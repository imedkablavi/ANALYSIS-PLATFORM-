classdef NetworkBehaviorExplorer < handle
    %NETWORKBEHAVIOREXPLORER Linked multimedia views over the analysis bundle.
    %
    %   app = NetworkBehaviorExplorer()          loads the default bundle
    %   app = NetworkBehaviorExplorer(bundle)    uses an in-memory bundle
    %   app = NetworkBehaviorExplorer(file)      loads a bundle .mat file
    %
    %   Built programmatically with the App Designer component family
    %   (uifigure / uigridlayout / uiaxes / uitable) so the source is plain
    %   text, reviewable and diffable (see docs/MULTIMEDIA_DESIGN.md).
    %   Callbacks are thin: every computation comes from src/ (plot*,
    %   getEntityContext, buildPlaybackFrame), which is unit-tested
    %   without a GUI.
    %
    %   Linked interaction (brushing & linking): selecting an entity in the
    %   ranking table, clicking a node in the network, or choosing a
    %   partner updates the network, timeline, spatial view and all detail
    %   tabs together. The time slider / Play button replays the network,
    %   map and timeline month by month; anomalous months are signalled
    %   visually and, optionally, by a short audio cue.

    properties (Access = public)
        Bundle
        Figure
    end

    properties (Access = private)
        Grid
        StatusLabel
        TimeSlider
        TimeLabel
        WindowSpinner
        PlayButton
        AudioBox
        FilterDrop
        RankTable
        DashboardText
        NetAxes
        TimeAxes
        MapAxes
        Tabs
        ExplainText
        EvidenceAxes
        EventTable
        PartnerTable
        PatternTable
        DetectorAxes
        QualityTable
        PlayTimer
        Selected = []
        RankRows = []
        NetInfo = struct('nodes', [], 'plot', [])
        Months
        CursorIndex = 1
    end

    methods
        function app = NetworkBehaviorExplorer(source)
            if nargin < 1
                cfg = projectConfig();
                root = fileparts(fileparts(mfilename('fullpath')));
                source = fullfile(root, cfg.output.bundle_file);
            end
            if isstruct(source)
                app.Bundle = source;
            else
                if ~isfile(source)
                    error("MOSAIC:BundleMissing", ...
                        "Analysis bundle not found: %s. Run scripts/run_pipeline.m first.", source);
                end
                S = load(source, "bundle");
                app.Bundle = S.bundle;
            end
            app.buildUi();
            app.populate();
        end

        function delete(app)
            app.stopTimer();
            if ~isempty(app.Figure) && isvalid(app.Figure)
                delete(app.Figure);
            end
        end

        function selectEntity(app, entityIndex)
            %SELECTENTITY Update every linked view for one entity.
            b = app.Bundle;
            app.Selected = entityIndex;
            ctx = getEntityContext(b, entityIndex);
            cutoff = app.cursorTime();
            try
                app.NetInfo = plotEgoNetwork(app.NetAxes, b, entityIndex, 2, ...
                    b.config.app.max_graph_nodes, cutoff);
                app.NetInfo.plot.ButtonDownFcn = @(~, evt) app.onGraphClick(evt);
            catch ME
                app.showMessage(app.NetAxes, "Network view unavailable: " + ME.message);
            end
            plotActivityTimeline(app.TimeAxes, b, entityIndex, cutoff);
            [t0, t1] = app.window();
            plotSpatialView(app.MapAxes, b, entityIndex, t0, t1);
            plotEvidenceBars(app.EvidenceAxes, b, entityIndex);

            p = ctx.profile;
            header = sprintf("%s | status: %s | crimes: %d | co-offenders: %d | component size: %d", ...
                p.entity_id, ctx.status, p.event_count, p.degree, p.component_size);
            app.ExplainText.Value = [header; ""; ctx.explanation; ""; ...
                "Sequence tokens (partner state + move): " + joinStrings(ctx.events.token, " ")];

            ev = ctx.events;
            app.EventTable.Data = table(ev.seq_pos, string(ev.event_time, 'yyyy-MM-dd'), ...
                ev.num_offenders, ev.token, round(ev.surprisal_bits, 2), ...
                round(ev.x, 3), round(ev.y, 3), 'VariableNames', ...
                {'#','date','offenders','token','surprise_bits','x_norm','y_norm'});
            pt = ctx.partners;
            app.PartnerTable.Data = table(pt.partner_id, pt.shared_crimes, ...
                string(pt.first_time, 'yyyy-MM-dd'), string(pt.last_time, 'yyyy-MM-dd'), ...
                round(pt.partner_iforest_score, 3), 'VariableNames', ...
                {'partner','shared_crimes','first','last','partner_score'});
            app.PartnerTable.UserData = pt.partner_index;
            app.StatusLabel.Text = "Selected " + p.entity_id + " (" + ctx.status + ")";
        end

        function setCursor(app, k)
            %SETCURSOR Move the playback cursor to month K and redraw linked views.
            k = min(max(round(k), 1), numel(app.Months));
            app.CursorIndex = k;
            app.TimeSlider.Value = k;
            b = app.Bundle;
            tEnd = app.cursorTime();
            frame = buildPlaybackFrame(b, tEnd, app.WindowSpinner.Value);
            app.TimeLabel.Text = sprintf("%s to %s | %d crimes, %d active ties, %d new ties", ...
                string(frame.t0, 'yyyy-MM'), string(frame.t1 - days(1), 'yyyy-MM'), ...
                numel(frame.crime_rows), height(frame.edges), height(frame.new_edges));
            if frame.bin_is_anomalous
                app.TimeLabel.FontColor = [0.85 0.33 0.1];
                app.TimeLabel.Text = app.TimeLabel.Text + "  [unusual month]";
                if app.AudioBox.Value
                    app.audioCue();
                end
            else
                app.TimeLabel.FontColor = [0 0 0];
            end
            plotActivityTimeline(app.TimeAxes, b, app.Selected, tEnd);
            plotSpatialView(app.MapAxes, b, app.Selected, frame.t0, frame.t1);
            if ~isempty(app.Selected)
                app.NetInfo = plotEgoNetwork(app.NetAxes, b, app.Selected, 2, ...
                    b.config.app.max_graph_nodes, tEnd);
                app.NetInfo.plot.ButtonDownFcn = @(~, evt) app.onGraphClick(evt);
            end
            drawnow limitrate;
        end
    end

    methods (Access = private)
        function buildUi(app)
            app.Figure = uifigure('Name', 'Network Behaviour Explorer — anomaly analysis (not a guilt assessment)', ...
                'Position', [60 60 1500 900]);
            app.Figure.CloseRequestFcn = @(~, ~) delete(app);
            app.Grid = uigridlayout(app.Figure, [3 3]);
            app.Grid.RowHeight = {34, '1x', '1x'};
            app.Grid.ColumnWidth = {380, '1x', '1x'};

            toolbar = uigridlayout(app.Grid, [1 9]);
            toolbar.Layout.Row = 1;
            toolbar.Layout.Column = [1 3];
            toolbar.Padding = [0 0 0 0];
            toolbar.ColumnWidth = {90, 60, 60, 60, '1x', 70, 50, 60, 360};
            uibutton(toolbar, 'Text', 'Export', 'ButtonPushedFcn', @(~, ~) app.exportViews());
            app.PlayButton = uibutton(toolbar, 'Text', 'Play', 'ButtonPushedFcn', @(~, ~) app.togglePlay());
            uibutton(toolbar, 'Text', 'Step', 'ButtonPushedFcn', @(~, ~) app.setCursor(app.CursorIndex + 1));
            uibutton(toolbar, 'Text', 'Reset', 'ButtonPushedFcn', @(~, ~) app.setCursor(1));
            app.TimeSlider = uislider(toolbar, 'Limits', [1 2], 'Value', 1, ...
                'MajorTicks', [], 'MinorTicks', [], ...
                'ValueChangedFcn', @(s, ~) app.setCursor(s.Value));
            uilabel(toolbar, 'Text', 'Window (mo)', 'HorizontalAlignment', 'right');
            app.WindowSpinner = uispinner(toolbar, 'Limits', [1 36], 'Value', 12, ...
                'ValueChangedFcn', @(~, ~) app.setCursor(app.CursorIndex));
            app.AudioBox = uicheckbox(toolbar, 'Text', 'Audio', 'Value', app.Bundle.config.app.audio_cues);
            app.TimeLabel = uilabel(toolbar, 'Text', '');

            left = uigridlayout(app.Grid, [4 1]);
            left.Layout.Row = [2 3];
            left.Layout.Column = 1;
            left.RowHeight = {150, 22, 22, '1x'};
            app.DashboardText = uitextarea(left, 'Editable', 'off', 'FontSize', 11);
            app.StatusLabel = uilabel(left, 'Text', 'Select an entity in the ranking.');
            app.FilterDrop = uidropdown(left, 'Items', ...
                {'Flagged (either detector)', 'Top 200 by Isolation Forest', ...
                'Top 200 by baseline', 'All eligible'}, ...
                'ValueChangedFcn', @(~, ~) app.fillRanking());
            app.RankTable = uitable(left, 'CellSelectionCallback', @(~, evt) app.onRankSelect(evt));

            app.NetAxes = uiaxes(app.Grid);
            app.NetAxes.Layout.Row = 2;
            app.NetAxes.Layout.Column = 2;
            app.MapAxes = uiaxes(app.Grid);
            app.MapAxes.Layout.Row = 2;
            app.MapAxes.Layout.Column = 3;
            app.TimeAxes = uiaxes(app.Grid);
            app.TimeAxes.Layout.Row = 3;
            app.TimeAxes.Layout.Column = 2;

            app.Tabs = uitabgroup(app.Grid);
            app.Tabs.Layout.Row = 3;
            app.Tabs.Layout.Column = 3;
            t1 = uitab(app.Tabs, 'Title', 'Why flagged');
            g1 = uigridlayout(t1, [1 1]);
            app.ExplainText = uitextarea(g1, 'Editable', 'off');
            t2 = uitab(app.Tabs, 'Title', 'Deviation profile');
            g2 = uigridlayout(t2, [1 1]);
            app.EvidenceAxes = uiaxes(g2);
            t3 = uitab(app.Tabs, 'Title', 'Events');
            g3 = uigridlayout(t3, [1 1]);
            app.EventTable = uitable(g3);
            t4 = uitab(app.Tabs, 'Title', 'Partners');
            g4 = uigridlayout(t4, [1 1]);
            app.PartnerTable = uitable(g4, 'CellSelectionCallback', @(~, evt) app.onPartnerSelect(evt));
            t5 = uitab(app.Tabs, 'Title', 'Patterns');
            g5 = uigridlayout(t5, [1 1]);
            app.PatternTable = uitable(g5);
            t6 = uitab(app.Tabs, 'Title', 'Detectors');
            g6 = uigridlayout(t6, [1 1]);
            app.DetectorAxes = uiaxes(g6);
            t7 = uitab(app.Tabs, 'Title', 'Data quality');
            g7 = uigridlayout(t7, [1 1]);
            app.QualityTable = uitable(g7);
        end

        function populate(app)
            b = app.Bundle;
            e = b.entities;
            v = b.validation;
            ta = b.temporal;
            nTemporal = nnz(ta.crime_anomalies.is_high | ta.crime_anomalies.is_low);
            s = v.summary;
            app.DashboardText.Value = [ ...
                sprintf("Offenders: %d  |  co-offending ties: %d", height(e), height(b.relations)); ...
                sprintf("Crimes: %d  |  offender-crime rows: %d", height(b.crimes), height(b.events)); ...
                sprintf("Dates: %s to %s (day resolution)", string(s.date_min, 'yyyy-MM-dd'), string(s.date_max, 'yyyy-MM-dd')); ...
                sprintf("Validation: %s (%d warnings)", string(v.is_valid), numel(v.warnings)); ...
                sprintf("Scored (>= %d crimes): %d  |  flagged: IF %d, baseline %d", ...
                    b.anomaly.settings.min_events, nnz(e.eligible), nnz(e.iforest_flag), nnz(e.baseline_flag)); ...
                sprintf("Detector agreement: Spearman %.2f, top-k Jaccard %.2f", ...
                    b.anomaly.agreement.spearman, b.anomaly.agreement.topk_jaccard); ...
                sprintf("Unusual months: %d  |  change points: %d  |  space-time hotspots: %d", ...
                    nTemporal, height(ta.change_points), nnz(b.spatial.spaceTime.is_hotspot)); ...
                sprintf("Recurring pairs: %d  |  recurring groups (>=3): %d", ...
                    height(b.patterns.pairs), height(b.patterns.groups)); ...
                "Scores are deviations from a reference population, not guilt or risk."];

            app.Months = ta.series.bin_start + calmonths(1);   % cursor = end of month
            app.TimeSlider.Limits = [1 max(2, numel(app.Months))];
            app.TimeSlider.Value = numel(app.Months);
            app.CursorIndex = numel(app.Months);

            ng = b.patterns.ngrams;
            ng = ng(1:min(200, height(ng)), :);
            app.PatternTable.Data = ng;
            app.QualityTable.Data = b.validation.checks;
            plotScoreComparison(app.DetectorAxes, b);
            app.fillRanking();
            plotActivityTimeline(app.TimeAxes, b, [], app.cursorTime());
            plotSpatialView(app.MapAxes, b, []);
            app.showMessage(app.NetAxes, "Select an entity to show its co-offending network.");
            if ~isempty(app.RankRows)
                app.selectEntity(app.RankRows(1));
            end
        end

        function fillRanking(app)
            e = app.Bundle.entities;
            switch app.FilterDrop.Value
                case 'Flagged (either detector)'
                    idx = find(e.iforest_flag | e.baseline_flag);
                    key = min(e.iforest_rank(idx), e.baseline_rank(idx));
                case 'Top 200 by Isolation Forest'
                    idx = find(e.iforest_rank <= 200);
                    key = e.iforest_rank(idx);
                case 'Top 200 by baseline'
                    idx = find(e.baseline_rank <= 200);
                    key = e.baseline_rank(idx);
                otherwise
                    idx = find(e.eligible);
                    key = e.iforest_rank(idx);
                    if all(isnan(key))
                        key = e.baseline_rank(idx);
                    end
            end
            [~, o] = sort(key);
            idx = idx(o);
            app.RankRows = idx;
            S = app.Bundle.explanations.summary;
            [has, loc] = ismember(idx, S.entity_index);
            dom = repmat("", numel(idx), 1);
            dom(has) = S.dominant_group(loc(has));
            app.RankTable.Data = table(e.entity_id(idx), e.iforest_rank(idx), ...
                round(e.iforest_score(idx), 3), e.baseline_rank(idx), ...
                round(e.baseline_score(idx), 2), e.event_count(idx), dom, ...
                'VariableNames', {'entity','IF_rank','IF_score','base_rank', ...
                'base_score','crimes','main_group'});
        end

        function onRankSelect(app, evt)
            if isempty(evt.Indices)
                return;
            end
            app.selectEntity(app.RankRows(evt.Indices(1, 1)));
        end

        function onPartnerSelect(app, evt)
            if isempty(evt.Indices) || isempty(app.PartnerTable.UserData)
                return;
            end
            app.selectEntity(app.PartnerTable.UserData(evt.Indices(1, 1)));
        end

        function onGraphClick(app, evt)
            p = app.NetInfo.plot;
            if isempty(p) || ~isvalid(p)
                return;
            end
            pt = evt.IntersectionPoint;
            [~, k] = min((p.XData - pt(1)).^2 + (p.YData - pt(2)).^2);
            app.selectEntity(app.NetInfo.nodes(k));
        end

        function t = cursorTime(app)
            if isempty(app.Months)
                t = NaT;
            else
                t = app.Months(app.CursorIndex);
            end
        end

        function [t0, t1] = window(app)
            t1 = app.cursorTime();
            t0 = t1 - calmonths(app.WindowSpinner.Value);
        end

        function togglePlay(app)
            if ~isempty(app.PlayTimer) && isvalid(app.PlayTimer) && ...
                    strcmp(app.PlayTimer.Running, 'on')
                app.stopTimer();
                app.PlayButton.Text = 'Play';
                return;
            end
            if app.CursorIndex >= numel(app.Months)
                app.setCursor(1);
            end
            app.PlayTimer = timer('ExecutionMode', 'fixedSpacing', 'Period', 0.8, ...
                'BusyMode', 'drop', 'TimerFcn', @(~, ~) app.tick());
            app.PlayButton.Text = 'Pause';
            start(app.PlayTimer);
        end

        function tick(app)
            if ~isvalid(app) || isempty(app.Figure) || ~isvalid(app.Figure)
                return;
            end
            if app.CursorIndex >= numel(app.Months)
                app.stopTimer();
                app.PlayButton.Text = 'Play';
                return;
            end
            app.setCursor(app.CursorIndex + 1);
        end

        function stopTimer(app)
            if ~isempty(app.PlayTimer) && isvalid(app.PlayTimer)
                stop(app.PlayTimer);
                delete(app.PlayTimer);
            end
            app.PlayTimer = [];
        end

        function audioCue(~)
            fs = 8192;
            tt = 0:1/fs:0.12;
            sound(0.2 * sin(2 * pi * 880 * tt), fs);
        end

        function exportViews(app)
            cfg = app.Bundle.config;
            root = fileparts(fileparts(mfilename('fullpath')));
            outDir = fullfile(root, cfg.output.figure_dir);
            if ~isfolder(outDir)
                mkdir(outDir);
            end
            stamp = string(datetime('now'), 'yyyyMMdd_HHmmss');
            exportgraphics(app.NetAxes, fullfile(outDir, "app_network_" + stamp + ".png"));
            exportgraphics(app.TimeAxes, fullfile(outDir, "app_timeline_" + stamp + ".png"));
            exportgraphics(app.MapAxes, fullfile(outDir, "app_spatial_" + stamp + ".png"));
            if ~isempty(app.Selected)
                writeTextFile(fullfile(root, cfg.output.report_dir, "entity_summary_" + stamp + ".txt"), ...
                    joinStrings(app.ExplainText.Value, newline));
            end
            app.StatusLabel.Text = "Exported to " + outDir;
        end

        function showMessage(~, ax, msg)
            cla(ax);
            text(ax, 0.5, 0.5, msg, 'HorizontalAlignment', 'center', 'Units', 'normalized');
            axis(ax, 'off');
        end
    end
end

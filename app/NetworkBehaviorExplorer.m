classdef NetworkBehaviorExplorer < handle
    %NETWORKBEHAVIOREXPLORER Linked multimedia views over an analysis bundle.
    %
    %   app = NetworkBehaviorExplorer()          loads the primary bundle, or
    %                                            opens an empty state that
    %                                            invites "Open dataset..."
    %   app = NetworkBehaviorExplorer(bundle)    uses an in-memory bundle
    %   app = NetworkBehaviorExplorer(file)      loads a bundle .mat file
    %   app.loadBundle(bundle)                   repopulates every view
    %
    %   Built programmatically with the App Designer component family
    %   (uifigure / uigridlayout / uipanel / uiaxes / uitable / uitabgroup /
    %   uiprogressdlg / uialert) so the source is plain text, reviewable and
    %   diffable (see docs/MULTIMEDIA_DESIGN.md). Callbacks are thin: every
    %   computation comes from src/ (plot*, getEntityContext,
    %   buildPlaybackFrame, filterRanking, kpiSummary, bundleDatasetInfo)
    %   and every colour/font from appTheme; those are unit-tested
    %   without a GUI.
    %
    %   Layout: header (title, dataset, format badge, dataset catalog,
    %   Open dataset..., Export) / left sidebar (KPI tiles, search, filter,
    %   ranking) / 2x2 titled panels (Network, Relative space, Timeline,
    %   Details) / replay bar / status bar with the disclaimer.
    %
    %   Linked interaction (brushing & linking): selecting an entity in the
    %   ranking table, clicking a node in the network, or choosing a
    %   partner updates the network, timeline, relative-space view, the
    %   detector scatter and all detail tabs together. The time slider /
    %   Play button replays the network, density view and timeline month by
    %   month; unusual months are signalled visually and, optionally, by a
    %   short audio cue.
    %
    %   Dataset import (Open dataset...) uses the dataset-import layer:
    %   inspectDatasetFile -> optional column-mapping dialog ->
    %   analyzeDataset (progress dialog) -> loadBundle; the dataset
    %   dropdown lists listDatasets(root) plus the primary bundle.

    properties (Access = public)
        Bundle
        Figure
    end

    properties (Access = private)
        Theme
        RootDir
        BundleFile = ""
        SearchText = ""
        MainGrid
        % Header
        DatasetLabel
        FormatBadge
        DatasetDrop
        OpenButton
        ExportButton
        % Sidebar
        KpiValues
        KpiDetails
        QualityDot
        SearchField
        FilterDrop
        RankCountLabel
        RankTable
        % Views
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
        % Replay bar
        ResetButton
        StepButton
        PlayButton
        TimeSlider
        WindowSpinner
        AudioBox
        TimeLabel
        % Status bar
        StatusLabel
        SelectionLabel
        % State
        PlayTimer
        Selected = []
        RankRows = []
        NetInfo = struct('nodes', [], 'plot', [])
        Months = NaT(0, 1)
        CursorIndex = 1
    end

    properties (Constant, Access = private)
        FilterItems = {'Flagged (either detector)', 'Top 200 by Isolation Forest', ...
            'Top 200 by baseline', 'All eligible'}
        Disclaimer = "Scores are statistical deviations, not evidence of wrongdoing"
        NoneItem = "(not used)"
    end

    methods
        function app = NetworkBehaviorExplorer(source)
            app.Theme = appTheme();
            app.RootDir = string(fileparts(fileparts(mfilename('fullpath'))));
            bundle = [];
            file = "";
            problem = "";
            if nargin < 1
                candidate = app.primaryBundleFile();
                if isfile(candidate)
                    file = candidate;
                end
            elseif isstruct(source)
                bundle = source;
            else
                file = string(source);
                if ~isfile(file)
                    problem = "Analysis bundle not found: " + file + ...
                        ". Run scripts/run_pipeline.m or use Open dataset.";
                    file = "";
                end
            end
            if strlength(file) > 0
                try
                    bundle = app.readBundleFile(file);
                catch ME
                    problem = "Could not load " + file + ": " + ME.message;
                    bundle = [];
                    file = "";
                end
            end
            app.buildUi();
            if isempty(bundle)
                app.showEmptyState();
            else
                app.loadBundle(bundle, file);
            end
            app.refreshDatasetList();
            if strlength(problem) > 0
                uialert(app.Figure, problem, 'Bundle not loaded');
            end
        end

        function delete(app)
            app.stopTimer();
            if ~isempty(app.Figure) && isvalid(app.Figure)
                delete(app.Figure);
            end
        end

        function loadBundle(app, bundle, sourceFile)
            %LOADBUNDLE Show BUNDLE in every view (constructor, catalog, import).
            %   SOURCEFILE (optional) is the .mat the bundle came from; it
            %   keeps the dataset dropdown in sync.
            if nargin < 3
                sourceFile = "";
            end
            app.stopTimer();
            app.PlayButton.Text = 'Play';
            app.Bundle = bundle;
            app.BundleFile = string(sourceFile);
            app.Selected = [];
            app.RankRows = [];
            app.NetInfo = struct('nodes', [], 'plot', []);
            app.SearchText = "";
            app.SearchField.Value = '';
            app.populate();
            app.syncDatasetDrop();
        end

        function selectEntity(app, entityIndex)
            %SELECTENTITY Update every linked view for one entity.
            b = app.Bundle;
            if isempty(b) || isempty(entityIndex)
                return;
            end
            ds = bundleDatasetInfo(b);
            try
                ctx = getEntityContext(b, entityIndex);
            catch ME
                app.setStatus("Could not read this entity: " + ME.message);
                return;
            end
            app.Selected = entityIndex;
            app.drawNetwork();
            app.safePlot(app.TimeAxes, @() plotActivityTimeline(app.TimeAxes, b, ...
                entityIndex, app.cursorTime()));
            [t0, t1] = app.window();
            app.safePlot(app.MapAxes, @() plotSpatialView(app.MapAxes, b, entityIndex, t0, t1));
            app.safePlot(app.EvidenceAxes, @() plotEvidenceBars(app.EvidenceAxes, b, entityIndex));
            app.safePlot(app.DetectorAxes, @() plotScoreComparison(app.DetectorAxes, b, entityIndex));

            p = ctx.profile;
            header = sprintf("%s | status: %s | %s: %d | partners: %d | component size: %d", ...
                string(p.entity_id), ctx.status, ds.event_plural, app.profileValue(p, 'event_count'), ...
                app.profileValue(p, 'degree'), app.profileValue(p, 'component_size'));
            app.ExplainText.Value = [header; ""; ctx.explanation; ""; ...
                "Sequence tokens (partner state + move): " + joinStrings(ctx.events.token, " ")];

            app.EventTable.Data = app.eventDisplayTable(ctx.events, ds.has_coordinates);
            pt = ctx.partners;
            app.PartnerTable.Data = table(pt.partner_id, pt.shared_crimes, ...
                string(pt.first_time, 'yyyy-MM-dd'), string(pt.last_time, 'yyyy-MM-dd'), ...
                round(pt.partner_iforest_score, 3), 'VariableNames', ...
                {'partner', 'shared_events', 'first', 'last', 'partner_score'});
            app.PartnerTable.UserData = pt.partner_index;
            app.SelectionLabel.Text = "Selected: " + string(p.entity_id) + " (" + ctx.status + ")";
            app.highlightRankRow();
        end

        function setCursor(app, k)
            %SETCURSOR Move the playback cursor to month K and redraw linked views.
            if isempty(app.Bundle) || isempty(app.Months)
                return;
            end
            k = min(max(round(k), 1), numel(app.Months));
            app.CursorIndex = k;
            app.TimeSlider.Value = k;
            b = app.Bundle;
            tEnd = app.cursorTime();
            frame = buildPlaybackFrame(b, tEnd, app.WindowSpinner.Value);
            ds = bundleDatasetInfo(b);
            txt = sprintf("%s to %s  ·  %d %s, %d active ties, %d new ties", ...
                string(frame.t0, 'yyyy-MM'), string(frame.t1 - days(1), 'yyyy-MM'), ...
                numel(frame.crime_rows), ds.event_plural, height(frame.edges), ...
                height(frame.new_edges));
            if frame.bin_is_anomalous
                app.TimeLabel.Text = txt + "  ·  Unusual month (triangles on the timeline)";
                app.TimeLabel.FontWeight = 'bold';
                if app.AudioBox.Value
                    app.audioCue();
                end
            else
                app.TimeLabel.Text = txt;
                app.TimeLabel.FontWeight = 'normal';
            end
            app.safePlot(app.TimeAxes, @() plotActivityTimeline(app.TimeAxes, b, ...
                app.Selected, tEnd));
            app.safePlot(app.MapAxes, @() plotSpatialView(app.MapAxes, b, app.Selected, ...
                frame.t0, frame.t1));
            if ~isempty(app.Selected)
                % Runs inside the Play timer: an error here must not kill the
                % timer while the button still says "Pause".
                try
                    app.NetInfo = plotEgoNetwork(app.NetAxes, b, app.Selected, 2, ...
                        app.maxGraphNodes(), app.networkCutoff());
                    app.NetInfo.plot.ButtonDownFcn = @(~, evt) app.onGraphClick(evt);
                catch ME
                    app.stopTimer();
                    app.PlayButton.Text = 'Play';
                    showAxesMessage(app.NetAxes, "Network view unavailable: " + ME.message, app.Theme);
                end
            end
            drawnow limitrate;
        end
    end

    methods (Access = private)
        %% ---------------------------------------------------------- layout
        function buildUi(app)
            th = app.Theme;
            app.Figure = uifigure('Name', 'Network Behaviour Explorer — statistical deviation analysis', ...
                'Position', [40 40 1560 940], 'Color', th.color.page);
            app.Figure.CloseRequestFcn = @(~, ~) delete(app);
            app.MainGrid = uigridlayout(app.Figure, [4 2]);
            g = app.MainGrid;
            g.RowHeight = {56, '1x', 52, 24};
            g.ColumnWidth = {390, '1x'};
            g.Padding = [10 6 10 6];
            g.RowSpacing = 8;
            g.ColumnSpacing = 10;
            app.setIf(g, 'BackgroundColor', th.color.page);

            app.buildHeader();
            app.buildSidebar();
            app.buildMainArea();
            app.buildReplayBar();
            app.buildStatusBar();
        end

        function buildHeader(app)
            th = app.Theme;
            panel = app.card(app.MainGrid, "");
            panel.Layout.Row = 1;
            panel.Layout.Column = [1 2];
            h = uigridlayout(panel, [1 8]);
            h.ColumnWidth = {'fit', 'fit', 'fit', '1x', 'fit', 280, 130, 90};
            h.RowHeight = {'1x'};
            h.Padding = [12 6 12 6];
            h.ColumnSpacing = 10;
            app.setIf(h, 'BackgroundColor', th.color.header);
            app.label(h, "Network Behaviour Explorer", th.font.header, th.color.text, 'bold');
            app.DatasetLabel = app.label(h, "No dataset loaded", th.font.base, ...
                th.color.textSecondary, 'normal');
            app.FormatBadge = app.label(h, "", th.font.small, th.color.text, 'normal');
            app.FormatBadge.HorizontalAlignment = 'center';
            app.FormatBadge.BackgroundColor = th.color.badge;
            app.label(h, "", th.font.small, th.color.text, 'normal');
            lbl = app.label(h, "Dataset", th.font.base, th.color.textSecondary, 'normal');
            lbl.HorizontalAlignment = 'right';
            app.DatasetDrop = uidropdown(h, 'Items', {'(no datasets)'}, 'ItemsData', {''}, ...
                'FontName', th.font.family, 'FontSize', th.font.base, ...
                'ValueChangedFcn', @(src, evt) app.onDatasetChosen(src, evt));
            app.OpenButton = uibutton(h, 'Text', ['Open dataset' char(8230)], ...
                'FontName', th.font.family, 'FontSize', th.font.base, 'FontWeight', 'bold', ...
                'BackgroundColor', th.color.accent, 'FontColor', th.color.accentText, ...
                'Tooltip', 'Import a JSON or CSV dataset and analyse it', ...
                'ButtonPushedFcn', @(~, ~) app.openDataset());
            app.ExportButton = uibutton(h, 'Text', 'Export', ...
                'FontName', th.font.family, 'FontSize', th.font.base, ...
                'BackgroundColor', th.color.surface, 'FontColor', th.color.text, ...
                'Tooltip', 'Save PNGs of the views and the evidence text to outputs/', ...
                'ButtonPushedFcn', @(~, ~) app.exportViews());
        end

        function buildSidebar(app)
            th = app.Theme;
            panel = app.card(app.MainGrid, "");
            panel.Layout.Row = 2;
            panel.Layout.Column = 1;
            s = uigridlayout(panel, [7 1]);
            s.RowHeight = {18, 210, 18, 26, 26, 16, '1x'};
            s.Padding = [10 10 10 10];
            s.RowSpacing = 6;
            app.setIf(s, 'BackgroundColor', th.color.surface);

            app.label(s, "OVERVIEW", th.font.small, th.color.textSecondary, 'bold');
            k = uigridlayout(s, [3 2]);
            k.RowHeight = {'1x', '1x', '1x'};
            k.ColumnWidth = {'1x', '1x'};
            k.Padding = [0 0 0 0];
            k.RowSpacing = 6;
            k.ColumnSpacing = 6;
            app.setIf(k, 'BackgroundColor', th.color.surface);
            labels = ["Entities", "Events", "Scored", "Flagged", "Unusual months", "Data quality"];
            app.KpiValues = gobjects(1, numel(labels));
            app.KpiDetails = gobjects(1, numel(labels));
            for i = 1:numel(labels)
                [valueLabel, detailLabel, dot] = app.kpiTile(k, labels(i), i == numel(labels));
                app.KpiValues(i) = valueLabel;
                app.KpiDetails(i) = detailLabel;
                if ~isempty(dot)
                    app.QualityDot = dot;
                end
            end

            app.label(s, "RANKING", th.font.small, th.color.textSecondary, 'bold');
            app.SearchField = uieditfield(s, 'text', 'FontName', th.font.family, ...
                'FontSize', th.font.base, ...
                'ValueChangingFcn', @(~, evt) app.onSearch(evt.Value), ...
                'ValueChangedFcn', @(src, ~) app.onSearch(src.Value));
            app.setIf(app.SearchField, 'Placeholder', 'Search entity ID');
            app.FilterDrop = uidropdown(s, 'Items', app.FilterItems, ...
                'FontName', th.font.family, 'FontSize', th.font.base, ...
                'ValueChangedFcn', @(~, ~) app.fillRanking());
            app.RankCountLabel = app.label(s, "", th.font.small, th.color.textSecondary, 'normal');
            app.RankTable = uitable(s, 'CellSelectionCallback', @(~, evt) app.onRankSelect(evt));
            app.styleTable(app.RankTable);
            app.RankTable.ColumnName = {'Entity', 'IF rank', 'IF score', 'Base rank', ...
                'Base score', 'Events', 'Main group'};
        end

        function [valueLabel, detailLabel, dot] = kpiTile(app, parent, labelText, isStatus)
            th = app.Theme;
            tile = uipanel(parent, 'BackgroundColor', th.color.surface, 'BorderType', 'line');
            app.setIf(tile, 'BorderColor', th.color.border);
            t = uigridlayout(tile, [3 1]);
            t.RowHeight = {14, '1x', 14};
            t.Padding = [8 4 8 4];
            t.RowSpacing = 0;
            app.setIf(t, 'BackgroundColor', th.color.surface);
            app.label(t, labelText, th.font.small, th.color.textSecondary, 'normal');
            dot = [];
            if isStatus
                row = uigridlayout(t, [1 2]);
                row.ColumnWidth = {16, '1x'};
                row.Padding = [0 0 0 0];
                row.ColumnSpacing = 4;
                app.setIf(row, 'BackgroundColor', th.color.surface);
                dot = app.label(row, string(char(9679)), th.font.header, th.color.textMuted, 'normal');
                valueLabel = app.label(row, "—", th.font.base + 2, th.color.text, 'bold');
            else
                valueLabel = app.label(t, "—", th.font.kpi, th.color.text, 'bold');
            end
            detailLabel = app.label(t, "", th.font.small, th.color.textSecondary, 'normal');
        end

        function buildMainArea(app)
            th = app.Theme;
            m = uigridlayout(app.MainGrid, [2 2]);
            m.Layout.Row = 2;
            m.Layout.Column = 2;
            m.RowHeight = {'1x', '1x'};
            m.ColumnWidth = {'1x', '1x'};
            m.Padding = [0 0 0 0];
            m.RowSpacing = 8;
            m.ColumnSpacing = 8;
            app.setIf(m, 'BackgroundColor', th.color.page);

            app.NetAxes = app.axesPanel(m, "Network", 1, 1);
            app.MapAxes = app.axesPanel(m, "Relative space", 1, 2);
            app.TimeAxes = app.axesPanel(m, "Timeline", 2, 1);

            dp = app.card(m, "Details");
            dp.Layout.Row = 2;
            dp.Layout.Column = 2;
            dg = uigridlayout(dp, [1 1]);
            dg.Padding = [4 4 4 4];
            app.setIf(dg, 'BackgroundColor', th.color.surface);
            app.Tabs = uitabgroup(dg);
            g1 = app.tabGrid("Why flagged");
            app.ExplainText = uitextarea(g1, 'Editable', 'off', 'FontName', th.font.family, ...
                'FontSize', th.font.base, 'FontColor', th.color.text, ...
                'BackgroundColor', th.color.surface);
            g2 = app.tabGrid("Deviation profile");
            app.EvidenceAxes = app.themedAxes(g2);
            g3 = app.tabGrid("Events");
            app.EventTable = uitable(g3);
            app.styleTable(app.EventTable);
            g4 = app.tabGrid("Partners");
            app.PartnerTable = uitable(g4, 'CellSelectionCallback', @(~, evt) app.onPartnerSelect(evt));
            app.styleTable(app.PartnerTable);
            g5 = app.tabGrid("Patterns");
            app.PatternTable = uitable(g5);
            app.styleTable(app.PatternTable);
            g6 = app.tabGrid("Detectors");
            app.DetectorAxes = app.themedAxes(g6);
            g7 = app.tabGrid("Data quality");
            app.QualityTable = uitable(g7);
            app.styleTable(app.QualityTable);
        end

        function buildReplayBar(app)
            th = app.Theme;
            panel = app.card(app.MainGrid, "");
            panel.Layout.Row = 3;
            panel.Layout.Column = [1 2];
            r = uigridlayout(panel, [1 9]);
            r.ColumnWidth = {'fit', 70, 70, 80, '1x', 'fit', 70, 'fit', 430};
            r.RowHeight = {'1x'};
            r.Padding = [12 4 12 4];
            r.ColumnSpacing = 10;
            app.setIf(r, 'BackgroundColor', th.color.surface);
            app.label(r, "REPLAY", th.font.small, th.color.textSecondary, 'bold');
            app.ResetButton = app.plainButton(r, 'Reset', 'Back to the first month', ...
                @(~, ~) app.setCursor(1));
            app.StepButton = app.plainButton(r, 'Step', 'Advance one month', ...
                @(~, ~) app.setCursor(app.CursorIndex + 1));
            app.PlayButton = uibutton(r, 'Text', 'Play', 'FontName', th.font.family, ...
                'FontSize', th.font.base, 'FontWeight', 'bold', ...
                'BackgroundColor', th.color.accent, 'FontColor', th.color.accentText, ...
                'Tooltip', 'Play / pause the month-by-month replay', ...
                'ButtonPushedFcn', @(~, ~) app.togglePlay());
            app.TimeSlider = uislider(r, 'Limits', [1 2], 'Value', 1, ...
                'MajorTicks', [], 'MinorTicks', [], ...
                'ValueChangedFcn', @(s, ~) app.setCursor(s.Value));
            app.label(r, "Window (months)", th.font.base, th.color.textSecondary, 'normal');
            app.WindowSpinner = uispinner(r, 'Limits', [1 36], 'Value', 12, ...
                'FontName', th.font.family, 'FontSize', th.font.base, ...
                'ValueChangedFcn', @(~, ~) app.setCursor(app.CursorIndex));
            app.AudioBox = uicheckbox(r, 'Text', 'Audio cue', 'Value', false, ...
                'FontName', th.font.family, 'FontSize', th.font.base, ...
                'FontColor', th.color.textSecondary);
            app.TimeLabel = app.label(r, "", th.font.base, th.color.text, 'normal');
        end

        function buildStatusBar(app)
            th = app.Theme;
            s = uigridlayout(app.MainGrid, [1 3]);
            s.Layout.Row = 4;
            s.Layout.Column = [1 2];
            s.ColumnWidth = {'1x', '1x', 'fit'};
            s.RowHeight = {'1x'};
            s.Padding = [4 0 4 0];
            app.setIf(s, 'BackgroundColor', th.color.page);
            app.StatusLabel = app.label(s, "Ready.", th.font.small, th.color.textSecondary, 'normal');
            app.SelectionLabel = app.label(s, "No selection", th.font.small, th.color.text, 'normal');
            d = app.label(s, app.Disclaimer, th.font.small, th.color.textSecondary, 'normal');
            d.FontAngle = 'italic';
            d.HorizontalAlignment = 'right';
        end

        %% -------------------------------------------------- layout helpers
        function p = card(app, parent, titleText)
            th = app.Theme;
            p = uipanel(parent, 'BackgroundColor', th.color.surface, 'BorderType', 'line', ...
                'FontName', th.font.family, 'FontSize', th.font.title, 'FontWeight', 'bold', ...
                'ForegroundColor', th.color.text);
            if strlength(titleText) > 0
                p.Title = char(titleText);
            end
            app.setIf(p, 'BorderColor', th.color.border);
        end

        function ax = axesPanel(app, parent, titleText, row, col)
            p = app.card(parent, titleText);
            p.Layout.Row = row;
            p.Layout.Column = col;
            g = uigridlayout(p, [1 1]);
            g.Padding = [6 6 6 6];
            app.setIf(g, 'BackgroundColor', app.Theme.color.surface);
            ax = app.themedAxes(g);
        end

        function ax = themedAxes(app, parent)
            ax = uiaxes(parent);
            app.setIf(ax, 'BackgroundColor', app.Theme.color.surface);
            styleAxes(ax, app.Theme);
        end

        function g = tabGrid(app, titleText)
            t = uitab(app.Tabs, 'Title', char(titleText), ...
                'BackgroundColor', app.Theme.color.surface);
            g = uigridlayout(t, [1 1]);
            g.Padding = [4 4 4 4];
            app.setIf(g, 'BackgroundColor', app.Theme.color.surface);
        end

        function lbl = label(app, parent, txt, fontSize, color, weight)
            lbl = uilabel(parent, 'Text', char(txt), 'FontName', app.Theme.font.family, ...
                'FontSize', fontSize, 'FontColor', color, 'FontWeight', weight);
        end

        function b = plainButton(app, parent, txt, tip, fcn)
            th = app.Theme;
            b = uibutton(parent, 'Text', txt, 'FontName', th.font.family, ...
                'FontSize', th.font.base, 'BackgroundColor', th.color.surface, ...
                'FontColor', th.color.text, 'Tooltip', tip, 'ButtonPushedFcn', fcn);
        end

        function styleTable(app, t)
            th = app.Theme;
            t.FontName = th.font.family;
            t.FontSize = th.font.small + 1;
            t.ForegroundColor = th.color.text;
            t.BackgroundColor = [th.color.surface; th.color.stripe];
            app.setIf(t, 'RowStriping', 'on');
            t.RowName = {};
        end

        function setIf(~, h, name, value)
            % Properties added in later releases (e.g. BorderColor,
            % Placeholder) are styled when present and skipped otherwise.
            if isprop(h, name)
                h.(name) = value;
            end
        end

        %% ------------------------------------------------------ populate
        function populate(app)
            b = app.Bundle;
            th = app.Theme;
            ds = bundleDatasetInfo(b);
            app.DatasetLabel.Text = char(ds.name);
            app.FormatBadge.Text = char("  " + ds.format + "  ");
            app.setControlsEnabled(true);

            kpi = kpiSummary(b);
            for i = 1:numel(kpi.tiles)
                app.KpiValues(i).Text = char(kpi.tiles(i).value_text);
                app.KpiDetails(i).Text = char(kpi.tiles(i).detail);
            end
            q = kpi.tiles(end);
            if q.status == ""
                app.QualityDot.FontColor = th.color.textMuted;
            else
                app.QualityDot.FontColor = th.status.(char(q.status));
                app.KpiValues(end).Text = char(th.status.icon.(char(q.status)) + " " + q.value_text);
            end

            app.Months = NaT(0, 1);
            if isfield(b, 'temporal') && isfield(b.temporal, 'series') && height(b.temporal.series) > 0
                app.Months = b.temporal.series.bin_start + calmonths(1);   % cursor = end of month
            end
            nMonths = numel(app.Months);
            app.TimeSlider.Limits = [1 max(2, nMonths)];
            app.TimeSlider.Value = max(1, nMonths);
            app.CursorIndex = max(1, nMonths);
            replayOn = nMonths > 1;
            app.setReplayEnabled(replayOn);
            if replayOn
                app.TimeLabel.Text = "Full period  ·  press Play to replay month by month";
            else
                app.TimeLabel.Text = "Replay needs dated events";
            end
            app.TimeLabel.FontWeight = 'normal';
            app.AudioBox.Value = logical(cfgGet(app.bundleConfig(), "app.audio_cues", false));

            if isfield(b, 'patterns') && isfield(b.patterns, 'ngrams')
                ng = b.patterns.ngrams;
                app.PatternTable.Data = ng(1:min(200, height(ng)), :);
            else
                app.PatternTable.Data = table();
            end
            if isfield(b, 'validation') && isfield(b.validation, 'checks')
                app.QualityTable.Data = b.validation.checks;
            else
                app.QualityTable.Data = table();
            end
            app.safePlot(app.DetectorAxes, @() plotScoreComparison(app.DetectorAxes, b));
            app.fillRanking();
            app.safePlot(app.TimeAxes, @() plotActivityTimeline(app.TimeAxes, b, [], app.cursorTime()));
            app.safePlot(app.MapAxes, @() plotSpatialView(app.MapAxes, b, []));
            showAxesMessage(app.NetAxes, "Select an entity to show its " + ...
                lower(ds.network_label) + ".", th);
            showAxesMessage(app.EvidenceAxes, "Select an entity.", th);
            app.ExplainText.Value = {''};
            app.EventTable.Data = table();
            app.PartnerTable.Data = table();
            app.PartnerTable.UserData = [];
            app.SelectionLabel.Text = "No selection";
            app.setStatus("Loaded " + ds.name + " (" + ds.format + ").");
            if ~isempty(app.RankRows)
                app.selectEntity(app.RankRows(1));
            end
        end

        function showEmptyState(app)
            th = app.Theme;
            app.Bundle = [];
            app.BundleFile = "";
            app.Months = NaT(0, 1);
            app.RankRows = [];
            app.Selected = [];
            app.DatasetLabel.Text = 'No dataset loaded';
            app.FormatBadge.Text = '';
            for i = 1:numel(app.KpiValues)
                app.KpiValues(i).Text = '—';
                app.KpiDetails(i).Text = '';
            end
            app.QualityDot.FontColor = th.color.textMuted;
            app.RankTable.Data = table();
            app.RankCountLabel.Text = '';
            invite = ["No dataset loaded."; "Use Open dataset to import a JSON or CSV file,"; ...
                "or run scripts/run_pipeline.m for the primary dataset."];
            showAxesMessage(app.NetAxes, invite, th);
            showAxesMessage(app.TimeAxes, "The timeline appears after a dataset is loaded.", th);
            showAxesMessage(app.MapAxes, "The relative-space view appears after a dataset is loaded.", th);
            showAxesMessage(app.EvidenceAxes, "No dataset loaded.", th);
            showAxesMessage(app.DetectorAxes, "No dataset loaded.", th);
            app.TimeLabel.Text = '';
            app.setControlsEnabled(false);
            app.setReplayEnabled(false);
            app.setStatus("No dataset loaded. Use Open dataset in the header.");
        end

        function setControlsEnabled(app, tf)
            state = matlab.lang.OnOffSwitchState(tf);
            app.ExportButton.Enable = state;
            app.SearchField.Enable = state;
            app.FilterDrop.Enable = state;
        end

        function setReplayEnabled(app, tf)
            state = matlab.lang.OnOffSwitchState(tf);
            for h = [app.ResetButton, app.StepButton, app.PlayButton]
                h.Enable = state;
            end
            app.TimeSlider.Enable = state;
            app.WindowSpinner.Enable = state;
            app.AudioBox.Enable = state;
        end

        function setStatus(app, msg)
            if ~isempty(app.StatusLabel) && isvalid(app.StatusLabel)
                app.StatusLabel.Text = char(msg);
            end
        end

        %% ------------------------------------------------------- ranking
        function fillRanking(app)
            b = app.Bundle;
            if isempty(b)
                return;
            end
            S = table();
            if isfield(b, 'explanations') && isfield(b.explanations, 'summary')
                S = b.explanations.summary;
            end
            [rows, shown] = filterRanking(b.entities, S, app.FilterDrop.Value, app.SearchText);
            app.RankRows = rows;
            app.RankTable.Data = shown;
            app.RankCountLabel.Text = sprintf('%d shown', numel(rows));
            if strlength(app.SearchText) > 0
                app.RankCountLabel.Text = sprintf('%d shown matching "%s"', numel(rows), app.SearchText);
            end
            app.highlightRankRow();
        end

        function highlightRankRow(app)
            % Linked selection feedback: the selected entity's ranking row
            % is tinted, whichever view selected it.
            try
                removeStyle(app.RankTable);
                r = find(app.RankRows == app.Selected, 1);
                if ~isempty(r)
                    addStyle(app.RankTable, uistyle('BackgroundColor', app.Theme.color.selectedRow), 'row', r);
                end
            catch
                % uistyle is unavailable in old releases; selection still works.
            end
        end

        function onSearch(app, value)
            app.SearchText = string(value);
            app.fillRanking();
        end

        function onRankSelect(app, evt)
            if isempty(evt.Indices) || isempty(app.RankRows)
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

        %% -------------------------------------------------------- views
        function drawNetwork(app)
            b = app.Bundle;
            try
                app.NetInfo = plotEgoNetwork(app.NetAxes, b, app.Selected, 2, ...
                    app.maxGraphNodes(), app.networkCutoff());
                app.NetInfo.plot.ButtonDownFcn = @(~, evt) app.onGraphClick(evt);
            catch ME
                app.NetInfo = struct('nodes', [], 'plot', []);
                showAxesMessage(app.NetAxes, "Network view unavailable: " + ME.message, app.Theme);
            end
        end

        function safePlot(app, ax, fcn)
            % One failing view (e.g. a field an imported dataset lacks) shows
            % a message in its own panel instead of breaking the others.
            try
                fcn();
            catch ME
                showAxesMessage(ax, ["View unavailable:"; string(ME.message)], app.Theme);
            end
        end

        function T = eventDisplayTable(~, ev, hasCoordinates)
            % Columns present in the bundle's events table, in a fixed order.
            names = string(ev.Properties.VariableNames);
            T = table();
            if ismember("seq_pos", names), T.("#") = ev.seq_pos; end
            if ismember("event_time", names), T.date = string(ev.event_time, 'yyyy-MM-dd'); end
            if ismember("num_offenders", names), T.participants = ev.num_offenders; end
            if ismember("token", names), T.token = ev.token; end
            if ismember("surprisal_bits", names), T.surprise_bits = round(ev.surprisal_bits, 2); end
            if hasCoordinates && all(ismember(["x", "y"], names))
                T.x_norm = round(ev.x, 3);
                T.y_norm = round(ev.y, 3);
            end
        end

        function v = profileValue(~, p, name)
            % Profile columns an imported dataset may lack print as NaN.
            v = NaN;
            if ismember(name, p.Properties.VariableNames)
                v = double(p.(name)(1));
            end
        end

        function n = maxGraphNodes(app)
            n = cfgGet(app.bundleConfig(), "app.max_graph_nodes", 400);
        end

        function cfg = bundleConfig(app)
            cfg = struct();
            if isstruct(app.Bundle) && isfield(app.Bundle, 'config')
                cfg = app.Bundle.config;
            end
        end

        %% ------------------------------------------------------- replay
        function t = networkCutoff(app)
            % Ties are hidden by date only while replaying the past: at the
            % end of the series (default state) the full network is shown, so
            % the graph agrees with the Partners tab.
            if isempty(app.Months) || app.CursorIndex >= numel(app.Months)
                t = NaT;
            else
                t = app.Months(app.CursorIndex);
            end
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
            if isempty(app.Months)
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
            try
                if app.CursorIndex >= numel(app.Months)
                    app.stopTimer();
                    app.PlayButton.Text = 'Play';
                    return;
                end
                app.setCursor(app.CursorIndex + 1);
            catch ME
                app.stopTimer();
                app.PlayButton.Text = 'Play';
                app.setStatus("Replay stopped: " + ME.message);
            end
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

        %% ------------------------------------------------------- export
        function exportViews(app)
            if isempty(app.Bundle)
                uialert(app.Figure, 'Load a dataset before exporting.', 'Nothing to export');
                return;
            end
            try
                cfg = app.bundleConfig();
                ds = bundleDatasetInfo(app.Bundle);
                outDir = fullfile(app.RootDir, cfgGet(cfg, "output.figure_dir", fullfile("outputs", "figures")));
                if ~isfolder(outDir)
                    mkdir(outDir);
                end
                stamp = ds.id + "_" + string(datetime('now'), 'yyyyMMdd_HHmmss');
                exportgraphics(app.NetAxes, fullfile(outDir, "app_network_" + stamp + ".png"));
                exportgraphics(app.TimeAxes, fullfile(outDir, "app_timeline_" + stamp + ".png"));
                exportgraphics(app.MapAxes, fullfile(outDir, "app_spatial_" + stamp + ".png"));
                if ~isempty(app.Selected)
                    reportDir = fullfile(app.RootDir, cfgGet(cfg, "output.report_dir", fullfile("outputs", "reports")));
                    if ~isfolder(reportDir)
                        mkdir(reportDir);
                    end
                    writeTextFile(fullfile(reportDir, "entity_summary_" + stamp + ".txt"), ...
                        joinStrings(app.ExplainText.Value, newline));
                end
                app.setStatus("Exported to " + outDir);
            catch ME
                uialert(app.Figure, ME.message, 'Export failed');
            end
        end

        %% ------------------------------------------------------ datasets
        function f = primaryBundleFile(app)
            cfg = projectConfig();
            f = string(fullfile(app.RootDir, cfg.output.bundle_file));
        end

        function bundle = readBundleFile(~, file)
            S = load(file, "bundle");
            if ~isfield(S, 'bundle')
                error("MOSAIC:BundleMissing", "File %s does not contain a variable named bundle.", file);
            end
            bundle = S.bundle;
        end

        function f = resolvePath(app, f)
            f = string(f);
            if strlength(f) > 0 && ~isfile(f) && isfile(fullfile(app.RootDir, f))
                f = string(fullfile(app.RootDir, f));
            end
        end

        function catalog = readCatalog(app)
            catalog = table();
            if exist('listDatasets', 'file') == 0
                return;
            end
            try
                catalog = listDatasets(app.RootDir);
            catch ME
                app.setStatus("Dataset catalog unavailable: " + ME.message);
                catalog = table();
            end
        end

        function refreshDatasetList(app)
            items = strings(0, 1);
            files = strings(0, 1);
            primary = app.primaryBundleFile();
            if isfile(primary)
                items(end+1, 1) = "primary";
                files(end+1, 1) = primary;
            end
            catalog = app.readCatalog();
            for k = 1:height(catalog)
                items(end+1, 1) = string(catalog.name(k)) + "  ·  " + string(catalog.format(k)); %#ok<AGROW>
                files(end+1, 1) = app.resolvePath(catalog.bundle_file(k)); %#ok<AGROW>
            end
            if ~isempty(app.Bundle) && ~any(files == app.BundleFile)
                ds = bundleDatasetInfo(app.Bundle);
                items = [ds.name + " (in memory)"; items];
                files = [app.BundleFile; files];
            end
            if isempty(items)
                app.DatasetDrop.Items = {'(no datasets yet)'};
                app.DatasetDrop.ItemsData = {''};
                app.DatasetDrop.Enable = 'off';
                return;
            end
            app.DatasetDrop.Items = cellstr(items);
            app.DatasetDrop.ItemsData = cellstr(files);
            app.DatasetDrop.Enable = 'on';
            app.syncDatasetDrop();
        end

        function syncDatasetDrop(app)
            data = string(app.DatasetDrop.ItemsData);
            k = find(data == app.BundleFile, 1);
            if ~isempty(k)
                app.DatasetDrop.Value = app.DatasetDrop.ItemsData{k};
            end
        end

        function onDatasetChosen(app, src, evt)
            file = string(evt.Value);
            if strlength(file) == 0 || file == app.BundleFile
                return;
            end
            app.stopTimer();
            dlg = uiprogressdlg(app.Figure, 'Title', 'Loading dataset', ...
                'Message', 'Loading the analysis bundle...', 'Indeterminate', 'on');
            try
                bundle = app.readBundleFile(file);
                app.loadBundle(bundle, file);
                close(dlg);
            catch ME
                close(dlg);
                src.Value = evt.PreviousValue;
                uialert(app.Figure, ME.message, 'Could not load dataset');
            end
        end

        function tf = importApiAvailable(~)
            tf = exist('inspectDatasetFile', 'file') ~= 0 && exist('analyzeDataset', 'file') ~= 0;
        end

        function openDataset(app)
            if ~app.importApiAvailable()
                uialert(app.Figure, ['Dataset import is not available: inspectDatasetFile / ' ...
                    'analyzeDataset are not on the path (run scripts/setupProject).'], ...
                    'Import unavailable');
                return;
            end
            app.stopTimer();
            app.PlayButton.Text = 'Play';
            [f, p] = uigetfile({'*.json;*.csv;*.txt;*.tsv', 'Datasets (*.json, *.csv, *.txt, *.tsv)'}, ...
                'Open dataset');
            figure(app.Figure);   % uigetfile can leave the app window behind
            if isequal(f, 0)
                return;
            end
            path = string(fullfile(p, f));
            app.setStatus("Inspecting " + f + " ...");
            try
                info = inspectDatasetFile(path);
            catch ME
                uialert(app.Figure, ME.message, 'Could not read the file');
                app.setStatus("Import failed.");
                return;
            end
            if string(info.format) == "unknown"
                uialert(app.Figure, sprintf('The format of %s was not recognised.\n%s', f, info.message), ...
                    'Unsupported file');
                app.setStatus("Import cancelled: unknown format.");
                return;
            end
            [mapping, name, ok] = app.askImportOptions(info, string(f));
            if ~ok
                app.setStatus("Import cancelled.");
                return;
            end
            opts = struct('root_dir', app.RootDir);
            if info.needs_mapping
                opts.mapping = mapping;
            end
            if strlength(name) > 0
                opts.name = name;
            end
            dlg = uiprogressdlg(app.Figure, 'Title', 'Analysing dataset', ...
                'Message', char("Importing " + f), 'Value', 0, 'Cancelable', false);
            opts.progress = @(fraction, message) app.onProgress(dlg, fraction, message);
            try
                bundle = analyzeDataset(path, opts);
            catch ME
                close(dlg);
                uialert(app.Figure, ME.message, 'Analysis failed');
                app.setStatus("Import failed: " + ME.message);
                return;
            end
            close(dlg);
            try
                file = app.catalogFileFor(bundle);
                app.loadBundle(bundle, file);
                app.refreshDatasetList();
            catch ME
                uialert(app.Figure, ME.message, 'Could not display the dataset');
            end
        end

        function onProgress(~, dlg, fraction, message)
            % Progress must never abort the analysis it reports on.
            try
                if isvalid(dlg)
                    dlg.Value = min(max(double(fraction), 0), 1);
                    dlg.Message = char(string(message));
                    drawnow limitrate;
                end
            catch
            end
        end

        function file = catalogFileFor(app, bundle)
            file = "";
            ds = bundleDatasetInfo(bundle);
            catalog = app.readCatalog();
            if height(catalog) == 0
                return;
            end
            k = find(string(catalog.dataset_id) == ds.id, 1, 'last');
            if ~isempty(k)
                file = app.resolvePath(catalog.bundle_file(k));
            end
        end

        function [mapping, name, ok] = askImportOptions(app, info, fileName)
            %ASKIMPORTOPTIONS Modal dialog: column mapping (if needed) + name.
            th = app.Theme;
            needMap = logical(info.needs_mapping);
            if string(info.format) == "edge_csv"
                fields = ["source", "target", "time", "weight"];
                labels = ["Source entity", "Target entity", "Time", "Weight"];
                required = [true true true false];
            else
                fields = ["entity", "event", "time", "x", "y"];
                labels = ["Entity ID", "Event ID", "Time", "X coordinate", "Y coordinate"];
                required = [true false true false false];   % no event id -> one event per row
            end
            if ~needMap
                fields = strings(1, 0);
            end
            nRows = numel(fields) + 4;
            w = 480;
            h = 64 + 34 * nRows;
            fp = app.Figure.Position;
            dlg = uifigure('Name', 'Import dataset', 'WindowStyle', 'modal', ...
                'Position', [fp(1) + (fp(3) - w) / 2, fp(2) + (fp(4) - h) / 2, w, h], ...
                'Color', th.color.surface, 'Resize', 'off');
            dlg.UserData = struct('ok', false);
            dlg.CloseRequestFcn = @(src, ~) app.finishDialog(src, struct('ok', false));
            g = uigridlayout(dlg, [nRows 2]);
            g.ColumnWidth = {140, '1x'};
            g.RowHeight = [{'fit'}, repmat({26}, 1, nRows - 2), {32}];
            g.Padding = [16 16 16 16];
            app.setIf(g, 'BackgroundColor', th.color.surface);

            if needMap
                intro = sprintf(['%s (%s). Choose which column holds each field; ' ...
                    '* = required.'], fileName, info.format);
            else
                intro = sprintf('%s (%s). Columns were detected automatically.', ...
                    fileName, info.format);
            end
            msg = app.label(g, intro, th.font.base, th.color.text, 'normal');
            msg.Layout.Row = 1;
            msg.Layout.Column = [1 2];
            app.setIf(msg, 'WordWrap', 'on');

            items = [app.NoneItem, reshape(string(info.columns), 1, [])];
            drops = gobjects(1, numel(fields));
            for k = 1:numel(fields)
                txt = labels(k);
                if required(k)
                    txt = txt + " *";
                end
                fieldLabel = app.label(g, txt, th.font.base, th.color.textSecondary, 'normal');
                fieldLabel.Layout.Row = k + 1;
                fieldLabel.Layout.Column = 1;
                pre = app.NoneItem;
                if isfield(info.mapping, fields(k)) && any(items == string(info.mapping.(fields(k))))
                    pre = string(info.mapping.(fields(k)));
                end
                drops(k) = uidropdown(g, 'Items', cellstr(items), 'Value', char(pre), ...
                    'FontName', th.font.family, 'FontSize', th.font.base);
                drops(k).Layout.Row = k + 1;
                drops(k).Layout.Column = 2;
            end
            r = numel(fields) + 2;
            nameLabel = app.label(g, "Name (optional)", th.font.base, th.color.textSecondary, 'normal');
            nameLabel.Layout.Row = r;
            nameLabel.Layout.Column = 1;
            [~, stem] = fileparts(fileName);
            nameField = uieditfield(g, 'text', 'Value', char(stem), ...
                'FontName', th.font.family, 'FontSize', th.font.base);
            nameField.Layout.Row = r;
            nameField.Layout.Column = 2;
            note = app.label(g, "Identifiers are pseudonymized; the analysis may take a while.", ...
                th.font.small, th.color.textSecondary, 'normal');
            note.Layout.Row = r + 1;
            note.Layout.Column = [1 2];
            btns = uigridlayout(g, [1 3]);
            btns.Layout.Row = r + 2;
            btns.Layout.Column = [1 2];
            btns.ColumnWidth = {'1x', 100, 120};
            btns.Padding = [0 0 0 0];
            app.setIf(btns, 'BackgroundColor', th.color.surface);
            app.label(btns, "", th.font.base, th.color.text, 'normal');
            app.plainButton(btns, 'Cancel', 'Close without importing', ...
                @(~, ~) app.finishDialog(dlg, struct('ok', false)));
            uibutton(btns, 'Text', 'Analyse', 'FontName', th.font.family, ...
                'FontSize', th.font.base, 'FontWeight', 'bold', ...
                'BackgroundColor', th.color.accent, 'FontColor', th.color.accentText, ...
                'ButtonPushedFcn', @(~, ~) app.onImportOk(dlg, drops, fields, labels, required, nameField));

            uiwait(dlg);
            res = struct('ok', false);
            if isvalid(dlg)
                res = dlg.UserData;
                delete(dlg);
            end
            ok = isfield(res, 'ok') && res.ok;
            mapping = app.emptyMapping();
            name = "";
            if ok
                mapping = res.mapping;
                name = res.name;
            end
        end

        function onImportOk(app, dlg, drops, fields, labels, required, nameField)
            mapping = app.emptyMapping();
            missing = strings(1, 0);
            for k = 1:numel(fields)
                v = string(drops(k).Value);
                if v == app.NoneItem
                    if required(k)
                        missing(end+1) = labels(k); %#ok<AGROW>
                    end
                else
                    mapping.(fields(k)) = v;
                end
            end
            if ~isempty(missing)
                uialert(dlg, "Choose a column for: " + joinStrings(missing, ", "), 'Missing columns');
                return;
            end
            app.finishDialog(dlg, struct('ok', true, 'mapping', mapping, ...
                'name', strtrim(string(nameField.Value))));
        end

        function finishDialog(~, dlg, result)
            dlg.UserData = result;
            uiresume(dlg);
        end

        function m = emptyMapping(~)
            m = struct('entity', "", 'event', "", 'time', "", 'x', "", 'y', "", ...
                'source', "", 'target', "", 'weight', "");
        end
    end
end

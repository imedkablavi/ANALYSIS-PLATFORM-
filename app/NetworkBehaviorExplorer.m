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
        MainAreaGrid
        NetPanel
        DetailsPanel
        TimelinePanel
        % Header
        DatasetLabel
        FormatBadge
        DatasetDrop
        OpenButton
        ExportButton
        % Sidebar
        SummaryLabel
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
        TruthTable
        QualityTable
        ProvenanceTable
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
            % Interface language: last choice, Turkish by default.
            try
                uiText("--lang", getpref('NetworkBehaviourExplorer', 'lang', 'tr'));
            catch
                uiText("--lang", "tr");
            end
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
                    problem = uiText("The saved analysis could not be found. Use Open dataset to select a supported file.");
                    file = "";
                end
            end
            if strlength(file) > 0
                try
                    bundle = app.readBundleFile(file);
                catch ME
                    problem = uiText("Could not load the saved analysis: %s", ME.message);
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
                uialert(app.Figure, problem, char(uiText("Analysis not loaded")));
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
            app.PlayButton.Text = char(uiText("Play"));
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
                app.setStatus(uiText("Could not read this entity: %s", ME.message));
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
            app.ExplainText.Value = renderEntitySummary(b, entityIndex);

            if isfield(b, 'flows') && ~isempty(b.flows)
                [observations, total] = hostFlowEvidence(b, entityIndex, 2000);
                app.EventTable.Data = observations;
                app.ExplainText.Value = [string(app.ExplainText.Value); ""; ...
                    uiText("Supporting observations: %d of %d flows shown. Full-run scores; observations do not attribute a score to a particular flow.", ...
                        height(observations), total)];
            else
                app.EventTable.Data = app.eventDisplayTable(ctx.events, ds);
            end
            app.translateTableHeaders(app.EventTable);
            % Busy hosts have >100,000 partners: show the 500 strongest
            % (ctx.partners is sorted by shared events) so the table stays fast.
            pt = ctx.partners(1:min(500, height(ctx.partners)), :);
            app.PartnerTable.Data = table(pt.partner_id, pt.shared_crimes, ...
                string(pt.first_time, ds.time_format), string(pt.last_time, ds.time_format), ...
                round(pt.partner_iforest_score, 3), 'VariableNames', ...
                {'partner', 'shared_events', 'first', 'last', 'partner_score'});
            app.PartnerTable.UserData = pt.partner_index;
            app.translateTableHeaders(app.PartnerTable);
            app.PartnerTable.ColumnWidth = {100, 100, 150, 150, 110};
            sel = uiText("Selected: %s (%s)", string(p.entity_id), uiText(ctx.status));
            if ismember('truth', b.entities.Properties.VariableNames)
                % Shown after scoring, for evaluation; the detectors never use it.
                sel = sel + uiText("  ·  published label: %s", string(b.entities.truth(entityIndex)));
            end
            app.SelectionLabel.Text = sel;
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
            ds = bundleDatasetInfo(b);
            frame = buildPlaybackFrame(b, tEnd, app.WindowSpinner.Value * ds.bin_step);
            txt = uiText("%s to %s  ·  %d %s, %d active ties, %d new ties", ...
                string(frame.t0, ds.time_format), string(frame.t1 - seconds(1), ds.time_format), ...
                numel(frame.crime_rows), uiText(ds.event_plural), height(frame.edges), ...
                height(frame.new_edges));
            if frame.bin_is_anomalous
                app.TimeLabel.Text = txt + uiText("  ·  Unusual %s (triangles on the timeline)", uiText(ds.bin));
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
                    app.PlayButton.Text = char(uiText("Play"));
                    showAxesMessage(app.NetAxes, uiText("Network view unavailable: %s", ME.message), app.Theme);
                end
            end
            drawnow limitrate;
        end
    end

    methods (Access = private)
        %% ---------------------------------------------------------- layout
        function buildUi(app)
            % Layout (deliberately plain: one summary line instead of
            % dashboard tiles, white page, panels separated by space):
            %   header  | title · dataset · format          dataset ▾  Open  Export
            %   summary | hosts · flows · scored · flagged · unusual · quality
            %   ranking | network            | details (tabs)
            %           | timeline + replay controls (full width)
            %   status line
            th = app.Theme;
            screen = get(groot, 'ScreenSize');
            app.Figure = uifigure('Name', char(uiText("Network Behaviour Explorer")), ...
                'Position', [40 40 min(1560, screen(3)-80) min(940, screen(4)-100)], ...
                'Color', th.color.surface);
            app.Figure.CloseRequestFcn = @(~, ~) delete(app);
            app.Figure.Tag = 'NetworkBehaviorExplorer';
            app.MainGrid = uigridlayout(app.Figure, [4 2]);
            g = app.MainGrid;
            g.RowHeight = {82, 26, '1x', 44};
            g.ColumnWidth = {430, '1x'};
            g.Padding = [16 12 16 8];
            g.RowSpacing = 8;
            g.ColumnSpacing = 14;
            app.setIf(g, 'BackgroundColor', th.color.surface);

            app.buildHeader();
            app.buildSummary();
            app.buildSidebar();
            app.buildMainArea();
            app.buildStatusBar();
            app.Figure.SizeChangedFcn = @(~, ~) app.adjustLayout();
            app.adjustLayout();
        end

        function adjustLayout(app)
            % Stack the views in smaller windows. Fixed minimum heights
            % allow scrolling instead of shrinking plots below readable size.
            if isempty(app.MainAreaGrid) || ~isvalid(app.MainAreaGrid)
                return;
            end
            if app.Figure.Position(3) < 1280
                app.MainGrid.ColumnWidth = {360, '1x'};
                app.RankTable.ColumnWidth = {88, 58, 62, 70, 60};
                app.MainAreaGrid.RowHeight = {240, 280, 260};
                app.NetPanel.Layout.Row = 1;
                app.NetPanel.Layout.Column = [1 2];
                app.DetailsPanel.Layout.Row = 2;
                app.DetailsPanel.Layout.Column = [1 2];
                app.TimelinePanel.Layout.Row = 3;
            else
                app.MainGrid.ColumnWidth = {430, '1x'};
                app.RankTable.ColumnWidth = {108, 68, 74, 88, 68};
                % Move the third-row panel before reducing the grid rows.
                app.NetPanel.Layout.Row = 1;
                app.NetPanel.Layout.Column = 1;
                app.DetailsPanel.Layout.Row = 1;
                app.DetailsPanel.Layout.Column = 2;
                app.TimelinePanel.Layout.Row = 2;
                app.MainAreaGrid.RowHeight = {'1.2x', '1x'};
            end
        end

        function buildHeader(app)
            th = app.Theme;
            h = uigridlayout(app.MainGrid, [2 1]);
            h.Layout.Row = 1;
            h.Layout.Column = [1 2];
            h.ColumnWidth = {'1x'};
            h.RowHeight = {32, 34};
            h.Padding = [0 0 0 0];
            h.RowSpacing = 8;
            app.setIf(h, 'BackgroundColor', th.color.surface);
            identity = uigridlayout(h, [1 3]);
            identity.Layout.Row = 1;
            identity.ColumnWidth = {'fit', '1x', 'fit'};
            identity.Padding = [0 0 0 0];
            identity.ColumnSpacing = 20;
            app.setIf(identity, 'BackgroundColor', th.color.surface);
            app.label(identity, uiText("Network Behaviour Explorer"), th.font.header, th.color.text, 'bold');
            app.DatasetLabel = app.label(identity, uiText("No dataset loaded"), th.font.base, th.color.textSecondary, 'normal');
            app.FormatBadge = app.label(identity, "", th.font.small, th.color.textSecondary, 'normal');

            toolbar = uigridlayout(h, [1 5]);
            toolbar.Layout.Row = 2;
            toolbar.ColumnWidth = {'1x', 150, 110, 16, 130};
            toolbar.Padding = [0 0 0 0];
            toolbar.ColumnSpacing = 10;
            app.setIf(toolbar, 'BackgroundColor', th.color.surface);
            app.DatasetDrop = uidropdown(toolbar, 'Items', {char(uiText("No datasets available"))}, 'ItemsData', {''}, ...
                'FontName', th.font.family, 'FontSize', th.font.base, ...
                'Tooltip', char(uiText("Analysed datasets")), ...
                'ValueChangedFcn', @(src, evt) app.onDatasetChosen(src, evt));
            app.OpenButton = app.plainButton(toolbar, char(uiText("Open dataset…")), ...
                char(uiText("Import a dataset file and analyse it")), @(~, ~) app.openDataset());
            app.ExportButton = app.plainButton(toolbar, char(uiText("Export")), ...
                char(uiText("Export views and investigation evidence (JSON/CSV)")), @(~, ~) app.exportViews());
            app.label(toolbar, "", th.font.small, th.color.text, 'normal');
            uidropdown(toolbar, 'Items', {'Türkçe', 'English'}, 'ItemsData', {'tr', 'en'}, ...
                'Tag', 'LanguageSelector', ...
                'Value', char(uiText("--lang")), 'FontName', th.font.family, ...
                'FontSize', th.font.base, 'Tooltip', char(uiText("Language")), ...
                'ValueChangedFcn', @(~, evt) app.switchLanguage(evt.Value));
        end

        function buildSummary(app)
            th = app.Theme;
            app.SummaryLabel = app.label(app.MainGrid, "", th.font.base, th.color.textSecondary, 'normal');
            app.SummaryLabel.Layout.Row = 2;
            app.SummaryLabel.Layout.Column = [1 2];
        end

        function buildSidebar(app)
            th = app.Theme;
            s = uigridlayout(app.MainGrid, [5 1]);
            s.Layout.Row = 3;
            s.Layout.Column = 1;
            s.RowHeight = {24, 32, 32, 44, '1x'};
            s.Padding = [0 0 0 0];
            s.RowSpacing = 6;
            app.setIf(s, 'BackgroundColor', th.color.surface);
            app.label(s, uiText("Ranking"), th.font.title, th.color.text, 'bold');
            app.SearchField = uieditfield(s, 'text', 'FontName', th.font.family, ...
                'Tag', 'EntitySearch', ...
                'FontSize', th.font.base, ...
                'ValueChangingFcn', @(~, evt) app.onSearch(evt.Value), ...
                'ValueChangedFcn', @(src, ~) app.onSearch(src.Value));
            app.setIf(app.SearchField, 'Placeholder', char(uiText("Search ID")));
            app.FilterDrop = uidropdown(s, 'Items', cellfun(@(x) char(uiText(x)), app.FilterItems, ...
                'UniformOutput', false), 'ItemsData', app.FilterItems, ...
                'Tag', 'RankingFilter', ...
                'FontName', th.font.family, 'FontSize', th.font.base, ...
                'ValueChangedFcn', @(~, ~) app.fillRanking());
            app.RankCountLabel = app.label(s, "", th.font.small, th.color.textSecondary, 'normal');
            app.setIf(app.RankCountLabel, 'WordWrap', 'on');
            app.RankTable = uitable(s, 'CellSelectionCallback', @(~, evt) app.onRankSelect(evt));
            app.styleTable(app.RankTable);
            app.RankTable.ColumnName = cellfun(@(x) char(uiText(x)), {'ID', 'IF rank', ...
                'IF score', 'Base score', 'Events'}, 'UniformOutput', false);
            app.RankTable.ColumnWidth = {108, 68, 74, 88, 68};
        end

        function switchLanguage(app, lang)
            % Rebuild labels using the current in-memory run. Preserve the
            % investigation state; replay remains stopped after a language change.
            app.stopTimer();
            app.PlayButton.Text = char(uiText("Play"));
            selected = app.Selected;
            cursor = app.CursorIndex;
            windowLength = app.WindowSpinner.Value;
            filter = app.FilterDrop.Value;
            search = app.SearchText;
            audio = app.AudioBox.Value;
            uiText("--lang", lang);
            try
                setpref('NetworkBehaviourExplorer', 'lang', char(lang));
            catch
                % preferences are a convenience only
            end
            bundle = app.Bundle;
            file = app.BundleFile;
            pos = app.Figure.Position;
            if ~isempty(bundle)
                next = NetworkBehaviorExplorer(bundle);
            else
                % Explicit empty state avoids loading a newly created default run.
                next = NetworkBehaviorExplorer(struct([]));
            end
            next.Figure.Position = pos;
            next.BundleFile = file;
            next.refreshDatasetList();
            next.WindowSpinner.Value = windowLength;
            next.FilterDrop.Value = filter;
            next.SearchText = search;
            next.SearchField.Value = char(search);
            next.fillRanking();
            if ~isempty(bundle)
                next.AudioBox.Value = false;
                next.setCursor(cursor);
                if ~isempty(selected)
                    next.selectEntity(selected);
                end
            end
            next.AudioBox.Value = audio;
            delete(app);
        end

        function s = tokenPreview(~, tokens)
            % At most 40 tokens: a busy host has hundreds of thousands.
            n = numel(tokens);
            s = joinStrings(tokens(1:min(n, 40)), " ");
            if n > 40
                s = s + uiText(" ... (%d more)", n - 40);
            end
        end

        function buildMainArea(app)
            th = app.Theme;
            m = uigridlayout(app.MainGrid, [2 2]);
            app.MainAreaGrid = m;
            m.Layout.Row = 3;
            m.Layout.Column = 2;
            m.RowHeight = {'1.2x', '1x'};
            m.ColumnWidth = {'1x', '1x'};
            m.Padding = [0 0 0 0];
            m.RowSpacing = 10;
            m.ColumnSpacing = 14;
            app.setIf(m, 'BackgroundColor', th.color.surface);
            app.setIf(m, 'Scrollable', 'on');

            app.NetAxes = app.axesPanel(m, uiText("Network"), 1, 1);
            app.NetPanel = app.NetAxes.Parent.Parent;

            dp = app.card(m, uiText("Details"));
            app.DetailsPanel = dp;
            dp.Layout.Row = 1;
            dp.Layout.Column = 2;
            dg = uigridlayout(dp, [1 1]);
            dg.Padding = [0 0 0 0];
            app.setIf(dg, 'BackgroundColor', th.color.surface);
            app.Tabs = uitabgroup(dg);
            g1 = app.tabGrid(uiText("Why flagged"));
            app.ExplainText = uitextarea(g1, 'Editable', 'off', 'FontName', th.font.family, ...
                'FontSize', th.font.base, 'FontColor', th.color.text, ...
                'BackgroundColor', th.color.surface);
            g2 = app.tabGrid(uiText("Deviation profile"));
            app.EvidenceAxes = app.themedAxes(g2);
            g3 = app.tabGrid(uiText("Events"));
            app.EventTable = uitable(g3);
            app.styleTable(app.EventTable);
            g4 = app.tabGrid(uiText("Partners"));
            app.PartnerTable = uitable(g4, 'CellSelectionCallback', @(~, evt) app.onPartnerSelect(evt));
            app.styleTable(app.PartnerTable);
            g9 = app.tabGrid(uiText("Space"));
            app.MapAxes = app.themedAxes(g9);
            g5 = app.tabGrid(uiText("Patterns"));
            app.PatternTable = uitable(g5);
            app.styleTable(app.PatternTable);
            g6 = app.tabGrid(uiText("Detectors"));
            app.DetectorAxes = app.themedAxes(g6);
            g8 = app.tabGrid(uiText("Ground truth"));
            app.TruthTable = uitable(g8);
            app.styleTable(app.TruthTable);
            g7 = app.tabGrid(uiText("Data quality"));
            app.QualityTable = uitable(g7);
            app.styleTable(app.QualityTable);
            g10 = app.tabGrid(uiText("Provenance"));
            app.ProvenanceTable = uitable(g10);
            app.styleTable(app.ProvenanceTable);
            app.ProvenanceTable.ColumnName = {char(uiText("Field")), char(uiText("Value"))};
            app.ProvenanceTable.ColumnWidth = {210, 350};

            % Timeline with its replay controls directly underneath.
            tp = app.card(m, uiText("Timeline"));
            app.TimelinePanel = tp;
            tp.Layout.Row = 2;
            tp.Layout.Column = [1 2];
            tg = uigridlayout(tp, [2 1]);
            tg.RowHeight = {'1x', 60};
            tg.Padding = [0 0 0 0];
            tg.RowSpacing = 4;
            app.setIf(tg, 'BackgroundColor', th.color.surface);
            app.TimeAxes = app.themedAxes(tg);
            app.buildReplayBar(tg);
        end

        function buildReplayBar(app, parent)
            th = app.Theme;
            r = uigridlayout(parent, [2 7]);
            r.ColumnWidth = {76, 70, 76, '1x', 'fit', 64, 'fit'};
            r.RowHeight = {30, 20};
            r.Padding = [0 0 0 0];
            r.ColumnSpacing = 10;
            app.setIf(r, 'BackgroundColor', th.color.surface);
            app.ResetButton = app.plainButton(r, char(uiText("Reset")), char(uiText("Back to the first period")), ...
                @(~, ~) app.setCursor(1));
            app.StepButton = app.plainButton(r, char(uiText("Step")), char(uiText("Advance one period")), ...
                @(~, ~) app.setCursor(app.CursorIndex + 1));
            app.PlayButton = app.plainButton(r, char(uiText("Play")), char(uiText("Play / pause the replay")), ...
                @(~, ~) app.togglePlay());
            app.TimeSlider = uislider(r, 'Limits', [1 2], 'Value', 1, ...
                'Tag', 'ReplayCursor', ...
                'MajorTicks', [], 'MinorTicks', [], ...
                'ValueChangedFcn', @(s, ~) app.setCursor(s.Value));
            app.label(r, uiText("Window"), th.font.base, th.color.textSecondary, 'normal');
            app.WindowSpinner = uispinner(r, 'Limits', [1 120], 'Value', 12, ...
                'Tag', 'ReplayWindow', ...
                'Tooltip', char(uiText("Window length in timeline bins (months, weeks, days, hours or minutes)")), ...
                'FontName', th.font.family, 'FontSize', th.font.base, ...
                'ValueChangedFcn', @(~, ~) app.setCursor(app.CursorIndex));
            app.AudioBox = uicheckbox(r, 'Text', char(uiText("Sound")), 'Value', false, ...
                'Tag', 'ReplayAudio', ...
                'FontName', th.font.family, 'FontSize', th.font.base, ...
                'FontColor', th.color.textSecondary);
            app.TimeLabel = app.label(r, "", th.font.small, th.color.textSecondary, 'normal');
            app.TimeLabel.Layout.Row = 2;
            app.TimeLabel.Layout.Column = [1 7];
        end

        function buildStatusBar(app)
            th = app.Theme;
            s = uigridlayout(app.MainGrid, [2 2]);
            s.Layout.Row = 4;
            s.Layout.Column = [1 2];
            s.ColumnWidth = {'1x', '1x'};
            s.RowHeight = {20, 18};
            s.Padding = [0 0 0 0];
            app.setIf(s, 'BackgroundColor', th.color.surface);
            app.StatusLabel = app.label(s, uiText("Ready."), th.font.small, th.color.textSecondary, 'normal');
            app.SelectionLabel = app.label(s, uiText("No selection"), th.font.small, th.color.text, 'normal');
            app.SelectionLabel.Tag = 'SelectedEntity';
            d = app.label(s, uiText(app.Disclaimer), th.font.small, th.color.textSecondary, 'normal');
            d.Layout.Row = 2;
            d.Layout.Column = [1 2];
        end

        %% -------------------------------------------------- layout helpers
        function p = card(app, parent, titleText)
            th = app.Theme;
            p = uipanel(parent, 'BackgroundColor', th.color.surface, 'BorderType', 'none', ...
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
            g.Padding = [0 0 0 0];
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

        function translateTableHeaders(~, t)
            % Display labels follow the active language; machine-readable
            % table variable names and export schemas stay unchanged.
            if ~istable(t.Data)
                return;
            end
            names = string(t.Data.Properties.VariableNames);
            t.Data = localizeTableDisplay(t.Data);
            labels = names;
            widths = repmat({110}, 1, numel(names));
            for k = 1:numel(names)
                labels(k) = uiText(names(k));
                if ismember(names(k), ["time", "first", "last"])
                    widths{k} = 165;
                elseif ismember(names(k), ["protocol", "direction", "peer", "partner"])
                    widths{k} = 110;
                elseif ismember(names(k), ["message", "note"])
                    widths{k} = 440;
                elseif ismember(names(k), ["ngram", "token"])
                    widths{k} = 220;
                elseif ismember(names(k), ["duration_seconds", "malicious_not_scored"])
                    widths{k} = 150;
                end
            end
            t.ColumnName = cellstr(labels);
            t.ColumnWidth = widths;
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
            app.ProvenanceTable.Data = bundleProvenance(b);
            app.FormatBadge.Text = char(datasetFormatLabel(ds.format));
            app.setControlsEnabled(true);

            % One plain summary line instead of dashboard tiles.
            kpi = kpiSummary(b);
            parts = strings(1, 0);
            for i = 1:numel(kpi.tiles) - 1
                t = kpi.tiles(i);
                parts(end+1) = formatDisplayCount(t.value) + " " + uiText(lower(t.label)); %#ok<AGROW>
            end
            q = kpi.tiles(end);
            if kpi.quality_status == "critical"
                quality = uiText("invalid");
            elseif isnan(kpi.warnings)
                quality = uiText("not validated");
            elseif kpi.warnings == 0
                quality = uiText("valid");
            elseif kpi.warnings == 1
                quality = uiText("%d warning", kpi.warnings);
            else
                quality = uiText("%d warnings", kpi.warnings);
            end
            parts(end+1) = uiText("data quality: %s", quality);
            app.SummaryLabel.Text = char(joinStrings(parts, "   ·   "));
            if q.status == "critical"
                app.SummaryLabel.FontColor = th.status.critical;
            else
                app.SummaryLabel.FontColor = th.color.textSecondary;
            end

            app.Months = NaT(0, 1);
            if isfield(b, 'temporal') && isfield(b.temporal, 'series') && height(b.temporal.series) > 0
                app.Months = b.temporal.series.bin_start + ds.bin_step;   % cursor = end of bin
            end
            nMonths = numel(app.Months);
            app.TimeSlider.Limits = [1 max(2, nMonths)];
            app.TimeSlider.Value = max(1, nMonths);
            app.CursorIndex = max(1, nMonths);
            replayOn = nMonths > 1;
            app.setReplayEnabled(replayOn);
            if replayOn
                app.TimeLabel.Text = uiText("Full period  ·  press Play to replay %s by %s", ...
                    uiText(ds.bin), uiText(ds.bin));
            else
                app.TimeLabel.Text = uiText("Replay needs dated events");
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
            app.translateTableHeaders(app.PatternTable);
            app.translateTableHeaders(app.QualityTable);
            app.safePlot(app.DetectorAxes, @() plotScoreComparison(app.DetectorAxes, b));
            if ds.has_labels
                % Published labels: evaluation of the unsupervised detectors only.
                ev = b.ground_truth.evaluation;
                ev.roc_auc = round(ev.roc_auc, 3);
                ev.average_precision = round(ev.average_precision, 3);
                ev.chance_ap = round(ev.chance_ap, 3);
                ev.precision_at_k = round(ev.precision_at_k, 3);
                ev.recall_at_k = round(ev.recall_at_k, 3);
                app.TruthTable.Data = ev;
            else
                app.TruthTable.Data = table(uiText("This dataset has no published labels: " + ...
                    "results are deviations only, not verified detections."), ...
                    'VariableNames', {'note'});
            end
            app.translateTableHeaders(app.TruthTable);
            app.fillRanking();
            app.safePlot(app.TimeAxes, @() plotActivityTimeline(app.TimeAxes, b, [], app.cursorTime()));
            app.safePlot(app.MapAxes, @() plotSpatialView(app.MapAxes, b, []));
            showAxesMessage(app.NetAxes, uiText("Select an entity in the ranking to show its network."), th);
            showAxesMessage(app.EvidenceAxes, uiText("Select an entity."), th);
            app.ExplainText.Value = {''};
            app.EventTable.Data = table();
            app.PartnerTable.Data = table();
            app.PartnerTable.UserData = [];
            app.SelectionLabel.Text = uiText("No selection");
            app.setStatus(uiText("Loaded %s", ds.name + " (" + datasetFormatLabel(ds.format) + ")."));
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
            app.DatasetLabel.Text = char(uiText("No dataset loaded"));
            app.FormatBadge.Text = '';
            app.SummaryLabel.Text = '';
            app.RankTable.Data = table();
            app.RankCountLabel.Text = char(uiText("No dataset loaded"));
            app.ProvenanceTable.Data = table();
            invite = [uiText("No dataset loaded"); uiText("Use Open dataset to select a supported file.")];
            showAxesMessage(app.NetAxes, invite, th);
            showAxesMessage(app.TimeAxes, uiText("The timeline appears after a dataset is loaded."), th);
            showAxesMessage(app.MapAxes, uiText("The relative-space view appears after a dataset is loaded."), th);
            showAxesMessage(app.EvidenceAxes, uiText("No dataset loaded"), th);
            showAxesMessage(app.DetectorAxes, uiText("No dataset loaded"), th);
            app.TimeLabel.Text = '';
            app.setControlsEnabled(false);
            app.setReplayEnabled(false);
            app.setStatus(uiText("No dataset loaded. Use Open dataset in the header."));
        end

        function setControlsEnabled(app, tf)
            state = matlab.lang.OnOffSwitchState(tf);
            app.ExportButton.Enable = matlab.lang.OnOffSwitchState(tf && app.hasData());
            app.SearchField.Enable = state;
            app.FilterDrop.Enable = state;
        end

        function tf = hasData(app)
            b = app.Bundle;
            tf = isstruct(b) && isscalar(b) && isfield(b, 'entities') && ...
                istable(b.entities) && height(b.entities) > 0;
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
                app.RankRows = [];
                app.RankTable.Data = table();
                app.RankCountLabel.Text = char(uiText("No dataset loaded"));
                return;
            end
            S = table();
            if isfield(b, 'explanations') && isfield(b.explanations, 'summary')
                S = b.explanations.summary;
            end
            [rows, shown] = filterRanking(b.entities, S, app.FilterDrop.Value, app.SearchText);
            app.RankRows = rows;
            app.RankTable.Data = shown(:, {'entity','IF_rank','IF_score','base_score','events'});
            app.RankCountLabel.Text = char(uiText("%d shown", numel(rows)));
            if strlength(app.SearchText) > 0
                app.RankCountLabel.Text = char(uiText("%d shown matching ""%s""", numel(rows), app.SearchText));
            end
            if isempty(rows)
                if ~any(b.entities.eligible)
                    message = uiText("No entities have enough history to be scored.");
                elseif strlength(strtrim(app.SearchText)) > 0
                    message = uiText("No matches. Clear the search or change the filter.");
                elseif string(app.FilterDrop.Value) == "Flagged (either detector)"
                    message = uiText("No entities flagged by either detector.");
                elseif string(app.FilterDrop.Value) == "Top 200 by Isolation Forest" && ...
                        all(isnan(b.entities.iforest_rank))
                    message = uiText("Isolation Forest scores are unavailable. Choose another filter.");
                else
                    message = uiText("No ranked entities in this filter.");
                end
                app.RankCountLabel.Text = char(message);
            end
            app.RankCountLabel.Tooltip = app.RankCountLabel.Text;
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
                showAxesMessage(app.NetAxes, uiText("Network view unavailable: %s", ME.message), app.Theme);
            end
        end

        function safePlot(app, ax, fcn)
            % One failing view (e.g. a field an imported dataset lacks) shows
            % a message in its own panel instead of breaking the others.
            try
                fcn();
            catch ME
                showAxesMessage(ax, uiText("View unavailable: %s", ME.message), app.Theme);
            end
        end

        function T = eventDisplayTable(~, ev, ds)
            % Columns present in the bundle's events table, in a fixed order.
            % At most the first 2,000 events (a busy host has hundreds of
            % thousands; the full list is in the exported tables).
            ev = ev(1:min(2000, height(ev)), :);
            names = string(ev.Properties.VariableNames);
            T = table();
            fmt = 'yyyy-MM-dd';
            if ismember(ds.bin, ["hour", "minute"])
                fmt = 'yyyy-MM-dd HH:mm:ss';
            end
            if ismember("seq_pos", names), T.("#") = ev.seq_pos; end
            if ismember("event_time", names), T.time = string(ev.event_time, fmt); end
            if ismember("num_offenders", names), T.participants = ev.num_offenders; end
            if ismember("token", names), T.token = ev.token; end
            if ismember("surprisal_bits", names), T.surprise_bits = round(ev.surprisal_bits, 2); end
            if ds.has_coordinates && all(ismember(["x", "y"], names))
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
            t0 = t1 - app.WindowSpinner.Value * bundleDatasetInfo(app.Bundle).bin_step;
        end

        function togglePlay(app)
            if ~isempty(app.PlayTimer) && isvalid(app.PlayTimer) && ...
                    strcmp(app.PlayTimer.Running, 'on')
                app.stopTimer();
                app.PlayButton.Text = char(uiText("Play"));
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
            app.PlayButton.Text = char(uiText("Pause"));
            start(app.PlayTimer);
        end

        function tick(app)
            if ~isvalid(app) || isempty(app.Figure) || ~isvalid(app.Figure)
                return;
            end
            try
                if app.CursorIndex >= numel(app.Months)
                    app.stopTimer();
                    app.PlayButton.Text = char(uiText("Play"));
                    return;
                end
                app.setCursor(app.CursorIndex + 1);
            catch ME
                app.stopTimer();
                app.PlayButton.Text = char(uiText("Play"));
                app.setStatus(uiText("Replay stopped: %s", ME.message));
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
            if ~app.hasData()
                uialert(app.Figure, char(uiText("Load a dataset before exporting.")), char(uiText("Nothing to export")));
                return;
            end
            % Freeze the replay so all exported views and interval metadata
            % describe the same cursor, even when graphics yield callbacks.
            app.stopTimer();
            app.PlayButton.Text = char(uiText("Play"));
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
                    % Render measured fields again instead of rewriting digits
                    % in display text that may resemble a source identifier.
                    summary = renderEntitySummary(app.Bundle, app.Selected);
                    writeTextFile(fullfile(reportDir, "entity_summary_" + stamp + ".txt"), ...
                        joinStrings(summary, newline));
                    [t0, t1] = app.window();
                    exportInvestigation(app.Bundle, app.Selected, reportDir, t0, t1, 2000);
                end
                app.setStatus(uiText("Exported to %s", outDir));
            catch ME
                uialert(app.Figure, ME.message, char(uiText("Export failed")));
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
                app.setStatus(uiText("Dataset catalog unavailable: %s", ME.message));
                catalog = table();
            end
        end

        function refreshDatasetList(app)
            items = strings(0, 1);
            files = strings(0, 1);
            primary = app.primaryBundleFile();
            if isfile(primary)
                items(end+1, 1) = uiText("Default dataset");
                files(end+1, 1) = primary;
            end
            catalog = app.readCatalog();
            for k = 1:height(catalog)
                items(end+1, 1) = string(catalog.name(k)) + "  ·  " + datasetFormatLabel(catalog.format(k)); %#ok<AGROW>
                files(end+1, 1) = app.resolvePath(catalog.bundle_file(k)); %#ok<AGROW>
            end
            if ~isempty(app.Bundle) && ~any(files == app.BundleFile)
                ds = bundleDatasetInfo(app.Bundle);
                items = [uiText("%s (current analysis)", ds.name); items];
                files = [app.BundleFile; files];
            end
            if isempty(items)
                app.DatasetDrop.Items = {char(uiText("No datasets available"))};
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
            dlg = uiprogressdlg(app.Figure, 'Title', char(uiText("Loading dataset")), ...
                'Message', char(uiText("Loading the saved analysis…")), 'Indeterminate', 'on');
            try
                bundle = app.readBundleFile(file);
                app.loadBundle(bundle, file);
                close(dlg);
            catch ME
                close(dlg);
                src.Value = evt.PreviousValue;
                uialert(app.Figure, ME.message, char(uiText("Could not load dataset")));
            end
        end

        function tf = importApiAvailable(~)
            tf = exist('inspectDatasetFile', 'file') ~= 0 && exist('analyzeDataset', 'file') ~= 0;
        end

        function openDataset(app)
            if ~app.importApiAvailable()
                uialert(app.Figure, char(uiText("Dataset import is unavailable. Restart the application and try again.")), ...
                    char(uiText("Import unavailable")));
                return;
            end
            app.stopTimer();
            app.PlayButton.Text = char(uiText("Play"));
            [f, p] = uigetfile({'*.json;*.csv;*.txt;*.tsv;*.binetflow', ...
                char(uiText("Supported datasets (*.json, *.csv, *.txt, *.tsv, *.binetflow)"))}, ...
                char(uiText("Open dataset")));
            figure(app.Figure);   % uigetfile can leave the app window behind
            if isequal(f, 0)
                return;
            end
            path = string(fullfile(p, f));
            app.setStatus(uiText("Inspecting %s…", f));
            try
                info = inspectDatasetFile(path);
            catch ME
                uialert(app.Figure, ME.message, char(uiText("Could not read the file")));
                app.setStatus(uiText("Import failed."));
                return;
            end
            if string(info.format) == "unknown" && isempty(info.columns)
                uialert(app.Figure, char(uiText("The format of %s was not recognised. Choose a supported dataset or a delimited file with entity and time columns.", f)), ...
                    char(uiText("Unsupported file")));
                app.setStatus(uiText("Import cancelled: unknown format."));
                return;
            end
            [opts, ok] = app.askImportOptions(info, string(f));
            if ~ok
                app.setStatus(uiText("Import cancelled."));
                return;
            end
            opts.root_dir = app.RootDir;
            dlg = uiprogressdlg(app.Figure, 'Title', char(uiText("Analysing dataset")), ...
                'Message', char(uiText("Importing %s…", f)), 'Value', 0, 'Cancelable', false);
            opts.progress = @(fraction, message) app.onProgress(dlg, fraction, message);
            try
                bundle = analyzeDataset(path, opts);
            catch ME
                close(dlg);
                uialert(app.Figure, ME.message, char(uiText("Analysis failed")));
                app.setStatus(uiText("Import failed: %s", ME.message));
                return;
            end
            close(dlg);
            try
                file = app.catalogFileFor(bundle);
                app.loadBundle(bundle, file);
                app.refreshDatasetList();
            catch ME
                uialert(app.Figure, ME.message, char(uiText("Could not display the dataset")));
            end
        end

        function onProgress(~, dlg, fraction, message)
            % Progress must never abort the analysis it reports on.
            try
                if isvalid(dlg)
                    dlg.Value = min(max(double(fraction), 0), 1);
                    dlg.Message = char(uiText(string(message)));
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

        function [opts, ok] = askImportOptions(app, info, fileName)
            % All text layouts can be corrected explicitly, including a
            % detected event list that should instead be read as flows.
            th = app.Theme;
            fp = app.Figure.Position;
            w = min(680, fp(3));
            h = min(760, fp(4));
            dlg = uifigure('Name', char(uiText("Import dataset")), 'WindowStyle', 'modal', ...
                'Position', [fp(1)+(fp(3)-w)/2, fp(2)+(fp(4)-h)/2, w, h], ...
                'Color', th.color.surface);
            dlg.CloseRequestFcn = @(src, ~) app.finishDialog(src, struct('ok', false));
            g = uigridlayout(dlg, [10 2]);
            g.ColumnWidth = {200, '1x'};
            g.RowHeight = {44, 32, '1x', 32, 32, 32, 32, 32, 40, 36};
            g.Padding = [16 16 16 16];
            app.setIf(g, 'BackgroundColor', th.color.surface);
            intro = app.label(g, uiText("Review the layout, columns and timestamps before analysing %s.", fileName), ...
                th.font.base, th.color.text, 'normal');
            intro.Layout.Row = 1; intro.Layout.Column = [1 2];
            app.setIf(intro, 'WordWrap', 'on');
            field = app.label(g, uiText("Data layout"), th.font.base, th.color.textSecondary, 'normal');
            field.Layout.Row = 2; field.Layout.Column = 1;
            layouts = ["event_csv", "edge_csv", "generic_network_flow"];
            titles = [uiText("Event participation rows"), uiText("Timestamped connections"), uiText("Network flow columns")];
            selected = string(info.format);
            if selected == "network_flow" && string(cfgGet(info,"profile","")) == "generic_network_flow"
                selected = "generic_network_flow";
            elseif selected == "network_flow"
                layouts = ["network_flow", layouts];
                titles = [uiText("Detected network profile"), titles];
            elseif selected == "networkx_burglary_json"
                layouts = selected;
                titles = uiText("Shared-event JSON");
            elseif ~any(layouts == selected)
                layouts = ["", layouts];
                titles = [uiText("Choose a data layout"), titles];
                selected = "";
            end
            layout = uidropdown(g, 'Items', cellstr(titles), 'ItemsData', cellstr(layouts), ...
                'Value', char(selected), 'FontName', th.font.family, 'FontSize', th.font.base);
            layout.Layout.Row = 2; layout.Layout.Column = 2;
            panel = uipanel(g, 'BorderType', 'none', 'BackgroundColor', th.color.surface);
            panel.Layout.Row = 3; panel.Layout.Column = [1 2];
            mg = uigridlayout(panel, [14 2]);
            mg.ColumnWidth = {200, '1x'};
            mg.Padding = [0 0 0 0];
            app.setIf(mg, 'BackgroundColor', th.color.surface);
            app.setIf(mg, 'Scrollable', 'on');
            roles = ["entity","event","source","target","time","weight","x","y", ...
                "duration","bytes","packets","sport","dport","proto"];
            labels = ["Entity ID","Event ID","Source entity","Target entity","Time","Weight", ...
                "X coordinate","Y coordinate","Duration (seconds)","Bytes","Packets", ...
                "Source port","Destination port","Protocol"];
            items = [app.NoneItem, reshape(string(info.columns),1,[])];
            displayItems = items; displayItems(1) = uiText(app.NoneItem);
            drops = gobjects(1,numel(roles));
            fieldLabels = gobjects(1,numel(roles));
            for k = 1:numel(roles)
                fieldLabels(k) = app.label(mg, uiText(labels(k)), th.font.base, th.color.textSecondary, 'normal');
                fieldLabels(k).Layout.Row = k; fieldLabels(k).Layout.Column = 1;
                pre = app.proposedImportColumn(info, roles(k));
                if ~any(items == pre), pre = app.NoneItem; end
                drops(k) = uidropdown(mg, 'Items', cellstr(displayItems), 'ItemsData', cellstr(items), ...
                    'Value', char(pre), 'FontName', th.font.family, 'FontSize', th.font.base);
                drops(k).Layout.Row = k; drops(k).Layout.Column = 2;
            end
            field = app.label(g, uiText("Timestamp unit"), th.font.base, th.color.textSecondary, 'normal');
            field.Layout.Row = 4; field.Layout.Column = 1;
            units = ["auto","posix_s","posix_ms","excel","datenum","yyyymmdd"];
            unitTitles = [uiText("Automatic"),uiText("Unix seconds"),uiText("Unix milliseconds"), ...
                uiText("Excel serial date"),uiText("MATLAB serial date"),"YYYYMMDD"];
            unit = uidropdown(g, 'Items', cellstr(unitTitles), 'ItemsData', cellstr(units), 'Value', 'auto', ...
                'FontName', th.font.family, 'FontSize', th.font.base);
            unit.Layout.Row = 4; unit.Layout.Column = 2;
            field = app.label(g, uiText("Timestamp format (optional)"), th.font.base, th.color.textSecondary, 'normal');
            field.Layout.Row = 5; field.Layout.Column = 1;
            timeFormat = uieditfield(g, 'text', 'FontName', th.font.family, 'FontSize', th.font.base);
            timeFormat.Layout.Row = 5; timeFormat.Layout.Column = 2;
            app.setIf(timeFormat, 'Placeholder', 'yyyy-MM-dd HH:mm:ss');
            field = app.label(g, uiText("First record"), th.font.base, th.color.textSecondary, 'normal');
            field.Layout.Row = 6; field.Layout.Column = 1;
            first = uieditfield(g, 'numeric', 'Value', 1, 'Limits', [1 Inf], ...
                'FontName', th.font.family, 'FontSize', th.font.base);
            first.Layout.Row = 6; first.Layout.Column = 2;
            field = app.label(g, uiText("Max records (0 = all)"), th.font.base, th.color.textSecondary, 'normal');
            field.Layout.Row = 7; field.Layout.Column = 1;
            maximum = uieditfield(g, 'numeric', 'Value', 0, 'Limits', [0 Inf], ...
                'FontName', th.font.family, 'FontSize', th.font.base);
            maximum.Layout.Row = 7; maximum.Layout.Column = 2;
            field = app.label(g, uiText("Name (optional)"), th.font.base, th.color.textSecondary, 'normal');
            field.Layout.Row = 8; field.Layout.Column = 1;
            [~, stem] = fileparts(fileName);
            name = uieditfield(g, 'text', 'Value', char(stem), 'FontName', th.font.family, 'FontSize', th.font.base);
            name.Layout.Row = 8; name.Layout.Column = 2;
            note = app.label(g, uiText("Required columns are marked *. Record limits apply to network flows."), ...
                th.font.small, th.color.textSecondary, 'normal');
            note.Layout.Row = 9; note.Layout.Column = [1 2];
            app.setIf(note, 'WordWrap', 'on');
            buttons = uigridlayout(g, [1 3]);
            buttons.Layout.Row = 10; buttons.Layout.Column = [1 2];
            buttons.ColumnWidth = {'1x',100,120}; buttons.Padding = [0 0 0 0];
            app.setIf(buttons, 'BackgroundColor', th.color.surface);
            app.label(buttons, "", th.font.small, th.color.text, 'normal');
            app.plainButton(buttons, char(uiText("Cancel")), char(uiText("Close without importing")), ...
                @(~, ~) app.finishDialog(dlg, struct('ok', false)));
            app.plainButton(buttons, char(uiText("Analyse")), char(uiText("Analyse")), ...
                @(~, ~) app.onImportOk(dlg));
            controls = struct('layout',layout,'outerGrid',g,'mappingGrid',mg,'roles',roles,'labels',labels, ...
                'fieldLabels',fieldLabels,'drops',drops,'unit',unit,'timeFormat',timeFormat, ...
                'first',first,'maximum',maximum,'name',name);
            dlg.UserData = struct('ok',false,'info',info,'controls',controls);
            layout.ValueChangedFcn = @(~, ~) app.updateImportLayout(dlg);
            app.updateImportLayout(dlg);
            uiwait(dlg);
            opts = struct(); ok = false;
            if isvalid(dlg)
                result = dlg.UserData;
                ok = isfield(result,'ok') && result.ok;
                if ok, opts = result.options; end
                delete(dlg);
            end
        end

        function updateImportLayout(app, dlg)
            c = dlg.UserData.controls;
            layout = string(c.layout.Value);
            fields = strings(1,0); required = strings(1,0);
            if layout == "event_csv"
                fields = ["entity","event","time","x","y"]; required = ["entity","time"];
            elseif layout == "edge_csv"
                fields = ["source","target","time","weight"]; required = ["source","target","time"];
            elseif layout == "generic_network_flow"
                fields = ["source","target","time","duration","bytes","packets","sport","dport","proto"];
                required = ["source","target","time"];
            end
            heights = repmat({0},1,numel(c.roles));
            for k = 1:numel(c.roles)
                shown = ismember(c.roles(k), fields);
                c.drops(k).Visible = matlab.lang.OnOffSwitchState(shown);
                c.fieldLabels(k).Visible = matlab.lang.OnOffSwitchState(shown);
                if shown, heights{k} = 32; end
                text = uiText(c.labels(k));
                if ismember(c.roles(k),required), text = text + " *"; end
                c.fieldLabels(k).Text = char(text);
            end
            c.mappingGrid.RowHeight = heights;
            outerRows = c.outerGrid.RowHeight;
            if isempty(fields), outerRows{3} = 0; else, outerRows{3} = '1x'; end
            c.outerGrid.RowHeight = outerRows;
            c.first.Enable = matlab.lang.OnOffSwitchState(ismember(layout,["network_flow","generic_network_flow"]));
            c.maximum.Enable = c.first.Enable;
            c.unit.Enable = matlab.lang.OnOffSwitchState(layout ~= "networkx_burglary_json");
            c.timeFormat.Enable = c.unit.Enable;
        end

        function column = proposedImportColumn(~, info, role)
            column = string(cfgGet(info.mapping, role, ""));
            if strlength(column) > 0, return; end
            aliases = role;
            switch role
                case "source", aliases = ["src","srcaddr","source","source_ip","src_ip"];
                case "target", aliases = ["dst","dstaddr","target","destination","destination_ip","dst_ip"];
                case "time", aliases = ["timestamp","time","starttime","stime","date"];
                case "duration", aliases = ["duration","duration_s","dur","flow_duration"];
                case "bytes", aliases = ["bytes","totbytes","total_bytes"];
                case "packets", aliases = ["packets","totpkts","total_packets"];
                case "sport", aliases = ["sport","src_port","source_port"];
                case "dport", aliases = ["dport","dst_port","destination_port"];
                case "proto", aliases = ["proto","protocol"];
            end
            names = reshape(string(info.columns),1,[]);
            for alias = aliases
                k = find(strcmpi(names,alias),1);
                if ~isempty(k), column = names(k); return; end
            end
        end

        function onImportOk(app, dlg)
            c = dlg.UserData.controls;
            form = struct('layout',string(c.layout.Value),'mapping',struct(), ...
                'name',string(c.name.Value),'time_unit',string(c.unit.Value), ...
                'time_format',string(c.timeFormat.Value),'first_row',c.first.Value,'max_rows',c.maximum.Value);
            for k = 1:numel(c.roles)
                value = string(c.drops(k).Value);
                if value == app.NoneItem, value = ""; end
                form.mapping.(c.roles(k)) = value;
            end
            try
                options = importDialogOptions(dlg.UserData.info,form);
            catch ME
                uialert(dlg, ME.message, char(uiText("Check import options")));
                return;
            end
            app.finishDialog(dlg, struct('ok',true,'options',options));
        end

        function finishDialog(~, dlg, result)
            dlg.UserData = result;
            uiresume(dlg);
        end

    end
end

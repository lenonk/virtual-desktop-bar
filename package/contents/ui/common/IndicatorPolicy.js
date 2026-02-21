.pragma library
.import "IndicatorStyles.js" as IndicatorStyles

function isVisible(style) {
    return style !== IndicatorStyles.UseLabels;
}

function isSideLine(style) {
    return style === IndicatorStyles.SideLine;
}

function usesFill(style) {
    return style === IndicatorStyles.Block ||
        style === IndicatorStyles.Rounded ||
        style === IndicatorStyles.FullSize;
}

function usesLabelMetrics(style) {
    return style > IndicatorStyles.EdgeLine;
}

function sideLineLabelReserve(style, config, indicatorLabelGap) {
    if (!isSideLine(style)) return 0;
    return config.IndicatorLineThickness + indicatorLabelGap;
}


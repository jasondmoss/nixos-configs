{
    runCommand,
    jq,
    kdePackages,
}:

#-- "Pie Chart (contrast)" sensor face for Plasma's System Monitor widgets.
#--
#-- A copy of libksysguard's own pie-chart face, made at build time so it
#-- follows Plasma updates. In a small panel the stock face overlays the
#-- value on the ring and puts a glow in Kirigami.Theme.backgroundColor behind
#-- it, and draws the ring track from backgroundColor too. Under the
#-- Perseverance Plasma Style both are dark whatever Panel Colorizer does —
#-- it only changes the text colour — so black text sat on a dark glow over a
#-- dark track. Here both key off the colour the value is actually drawn in:
#-- the glow is its opposite (white behind dark text, black behind light),
#-- the track a 30 % mix of the text colour into that opposite (light grey
#-- under dark text, dark grey under light). The track has to be opaque:
#-- QuickCharts' pie shader treats backgroundColor as premultiplied, so a
#-- translucent colour comes out near-white. With the theme's own light text
#-- it looks like the stock face.
#--
#-- --replace-fail makes an upstream change to the patched lines a build
#-- error rather than a silently unpatched face.

let
    id = "org.jdmlabs.contrastpie";
in

runCommand "panel-contrast-sensorface" {
    nativeBuildInputs = [ jq ];
    passthru.faceId = id;
} ''
    src=${kdePackages.libksysguard}/share/ksysguard/sensorfaces/org.kde.ksysguard.piechart
    face=$out/share/ksysguard/sensorfaces/${id}
    mkdir -p "$(dirname "$face")"
    cp -r --no-preserve=mode "$src" "$face"

    jq '.KPlugin |= (with_entries(select(.key | test("^(Name|Description)\\[") | not))
                     | .Id = "${id}"
                     | .Name = "Pie Chart (contrast)"
                     | .Description = "Pie chart whose value glow and ring track contrast with the text colour")' \
        "$src/metadata.json" > "$face/metadata.json"

    substituteInPlace "$face/contents/ui/UsedTotalDisplay.qml" \
        --replace-fail 'readonly property bool constrained: width < Kirigami.Units.gridUnit * 2' \
                       'readonly property bool constrained: width < Kirigami.Units.gridUnit * 2
    readonly property color textColor: usedValue.color
    readonly property color contrastColor: Kirigami.ColorUtils.brightnessForColor(usedValue.color) === Kirigami.ColorUtils.Dark ? "white" : "black"' \
        --replace-fail 'color: Kirigami.Theme.backgroundColor' \
                       'color: Qt.rgba(root.contrastColor.r, root.contrastColor.g, root.contrastColor.b, 0.9)'

    substituteInPlace "$face/contents/ui/PieChart.qml" \
        --replace-fail 'chart.backgroundColor: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.1)' \
                       'chart.backgroundColor: Kirigami.ColorUtils.linearInterpolation(totalDisplay.contrastColor, totalDisplay.textColor, 0.3)' \
        --replace-fail 'UsedTotalDisplay {' \
                       'UsedTotalDisplay {
        id: totalDisplay'
''

# <> #

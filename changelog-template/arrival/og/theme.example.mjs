// ORG's look for social cards (night palette, octagon wedges, perforated frame). Same values as the
// arrival kit's org.css "night" mode. Paths resolve against src/og/.
export const ORG_CARD_THEME = {
  background: "#100e1c",
  glows: ["rgba(155, 109, 255, 0.42)", "rgba(233, 190, 114, 0.30)", "rgba(111, 227, 214, 0.16)"],
  heading: "#f4effc",
  text: "#eee8f6",
  muted: "#b4abc9",
  accent: "#e9be72",
  ink: ["#b39bff", "#f08ccf", "#6fe3d6", "#f2c97f"],
  wedges: ["#5a43f0", "#9a4dff", "#d04ce8", "#e65aa8", "#f29a3a", "#e4d548", "#6fd84a", "#3ccfe0"],
  sides: 8,
  frame: "perforated",
  perf: "rgba(238, 232, 246, 0.30)",
  mark: null,
  fonts: {
    heading: { name: "Fraunces", files: { 400: "fonts/Fraunces-400.ttf", 600: "fonts/Fraunces-600.ttf" } },
    body: { name: "Manrope", files: { 500: "fonts/Manrope-500.ttf", 700: "fonts/Manrope-700.ttf" } },
  },
};

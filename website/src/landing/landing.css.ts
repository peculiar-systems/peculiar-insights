import { globalStyle, style } from "@vanilla-extract/css";
import { vars } from "../app/theme.css.ts";

export const hero = style({
  position: "relative",
  padding: "96px 0 56px",
  overflow: "hidden",
});

export const gridBg = style({
  position: "absolute",
  inset: 0,
  zIndex: 0,
  pointerEvents: "none",
  backgroundImage: `linear-gradient(${vars.color.line} 1px, transparent 1px), linear-gradient(90deg, ${vars.color.line} 1px, transparent 1px)`,
  backgroundSize: "64px 64px",
  maskImage: "radial-gradient(120% 90% at 80% 0%, #000 0%, transparent 62%)",
  opacity: 0.6,
});

export const inner = style({
  position: "relative",
  zIndex: 1,
  maxWidth: "800px",
});

export const catTag = style({
  display: "inline-flex",
  alignItems: "center",
  gap: "9px",
  fontFamily: vars.font.mono,
  fontSize: "12px",
  letterSpacing: ".12em",
  textTransform: "uppercase",
  color: vars.color.inkSoft,
});

export const catDot = style({
  width: "9px",
  height: "9px",
  borderRadius: "50%",
  background: vars.color.violet,
});

export const title = style({
  fontSize: "clamp(40px, 8vw, 80px)",
  margin: "18px 0 0",
});

export const titleDot = style({
  color: vars.color.violet,
});

export const tagline = style({
  fontFamily: vars.font.display,
  fontWeight: 500,
  fontSize: "clamp(20px, 3vw, 30px)",
  letterSpacing: "-0.015em",
  marginTop: "18px",
  maxWidth: "30ch",
});

export const blurb = style({
  marginTop: "20px",
  fontSize: "18px",
  color: vars.color.inkSoft,
  maxWidth: "60ch",
});

globalStyle(`${blurb} b`, { color: vars.color.ink, fontWeight: 600 });

export const ctas = style({
  display: "flex",
  flexWrap: "wrap",
  gap: "12px",
  marginTop: "28px",
});

export const trust = style({
  marginTop: "18px",
  fontFamily: vars.font.mono,
  fontSize: "12.5px",
  color: vars.color.inkFaint,
  letterSpacing: ".01em",
});

export const why = style({
  marginTop: "28px",
  maxWidth: "64ch",
  borderLeft: `3px solid ${vars.color.violet}`,
  padding: "4px 0 4px 18px",
});

export const whyTitle = style({
  fontSize: "13px",
  textTransform: "uppercase",
  letterSpacing: ".08em",
  color: vars.color.violetInk,
  margin: "0 0 8px",
});

export const whyText = style({
  margin: 0,
  fontSize: "16px",
  lineHeight: 1.55,
  color: vars.color.inkSoft,
});

export const section = style({
  padding: "56px 0",
});

export const sectionAlt = style([
  section,
  {
    background: vars.color.bg2,
    borderTop: `1px solid ${vars.color.line}`,
    borderBottom: `1px solid ${vars.color.line}`,
  },
]);

export const cards = style({
  display: "grid",
  gridTemplateColumns: "repeat(auto-fit, minmax(230px, 1fr))",
  gap: "14px",
  marginTop: "30px",
});

export const card = style({
  background: vars.color.surface,
  border: `1px solid ${vars.color.line}`,
  borderRadius: "14px",
  padding: "20px",
  boxShadow: vars.shadowSm,
});

export const cardKey = style({
  fontFamily: vars.font.mono,
  fontSize: "12px",
  color: vars.color.violetInk,
});

export const cardTitle = style({
  fontSize: "18px",
  margin: "8px 0 6px",
});

export const cardText = style({
  fontSize: "14.5px",
  color: vars.color.inkSoft,
});

globalStyle(`${cardText} code`, {
  fontSize: "13px",
  background: vars.color.bg2,
  padding: "1px 5px",
  borderRadius: "5px",
});

export const steps = style({
  display: "grid",
  gridTemplateColumns: "repeat(auto-fit, minmax(230px, 1fr))",
  gap: "14px",
  marginTop: "30px",
});

export const step = style({
  padding: "20px 0 0",
  borderTop: `2px solid ${vars.color.lineStrong}`,
});

export const stepNumber = style({
  fontFamily: vars.font.mono,
  fontSize: "12px",
  color: vars.color.violetInk,
});

export const stepTitle = style({
  fontSize: "18px",
  margin: "8px 0 6px",
});

export const diagram = style({
  marginTop: "30px",
  background: vars.color.surface,
  border: `1px solid ${vars.color.line}`,
  borderRadius: vars.radius,
  padding: "20px",
  boxShadow: vars.shadowSm,
  overflowX: "auto",
});

export const diagramSvg = style({
  display: "block",
  width: "100%",
  minWidth: "560px",
  height: "auto",
  fontFamily: vars.font.body,
});

export const codeGrid = style({
  display: "grid",
  gridTemplateColumns: "1fr 1fr",
  gap: "20px",
  marginTop: "30px",
  alignItems: "start",
  "@media": { "(max-width: 860px)": { gridTemplateColumns: "1fr" } },
});

export const codeBlock = style({
  minWidth: 0,
});

export const codeTitle = style({
  fontSize: "16px",
  marginBottom: "10px",
});

export const pre = style({
  background: vars.color.codeBg,
  color: vars.color.codeInk,
  borderRadius: "12px",
  padding: "16px 18px",
  fontSize: "13px",
  lineHeight: 1.55,
  overflow: "auto",
  maxWidth: "100%",
  fontFamily: vars.font.mono,
});

export const vocabulary = style({
  display: "flex",
  flexWrap: "wrap",
  gap: "8px",
  marginTop: "22px",
});

export const chip = style({
  display: "inline-flex",
  alignItems: "center",
  fontFamily: vars.font.mono,
  fontSize: "12.5px",
  padding: "5px 10px",
  borderRadius: "8px",
  background: vars.color.violetTint,
  color: vars.color.ink,
  border: `1px solid ${vars.color.violetTint2}`,
});

export const principles = style({
  display: "grid",
  gridTemplateColumns: "repeat(auto-fit, minmax(250px, 1fr))",
  gap: "14px",
  marginTop: "30px",
});

export const principle = style({
  background: vars.color.surface,
  border: `1px solid ${vars.color.line}`,
  borderRadius: "14px",
  padding: "20px",
  boxShadow: vars.shadowSm,
});

export const cta = style({
  marginTop: "30px",
  maxWidth: "720px",
  background: vars.color.surface,
  border: `1px solid ${vars.color.lineStrong}`,
  borderRadius: vars.radius,
  padding: "26px 28px",
  boxShadow: vars.shadowSm,
  "@media": { "(max-width: 480px)": { padding: "20px 16px" } },
});

export const ctaTitle = style({
  fontSize: "22px",
  letterSpacing: "-0.015em",
});

export const ctaText = style({
  fontSize: "14.5px",
  color: vars.color.inkSoft,
  marginTop: "6px",
});

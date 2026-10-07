import * as s from "./landing.css.ts";

const boxes = [
  { x: 20, label: "SDKs", sub: "Flutter · TS · Haskell" },
  { x: 240, label: "Ingest server", sub: "Haskell · gRPC, gRPC-Web, Connect" },
  { x: 460, label: "PostgreSQL", sub: "partitioned, reporting schema" },
  { x: 680, label: "Grafana", sub: "dashboards · alerts" },
] as const;

export const Diagram = () => (
  <div class={s.diagram}>
    <svg class={s.diagramSvg} viewBox="0 0 880 150" role="img" aria-labelledby="diagram-title">
      <title id="diagram-title">
        SDKs send consented batches to the ingest server, which stores them in PostgreSQL, which
        Grafana reads
      </title>
      {boxes.map((box, index) => (
        <g key={box.label}>
          <rect
            x={box.x}
            y={30}
            width={180}
            height={76}
            rx={14}
            fill="oklch(0.991 0.006 95)"
            stroke={index === 1 ? "oklch(0.55 0.26 296)" : "oklch(0.83 0.01 95)"}
            stroke-width={index === 1 ? 2 : 1.5}
          />
          <text
            x={box.x + 90}
            y={62}
            text-anchor="middle"
            font-size="16"
            font-weight="700"
            fill="oklch(0.21 0.012 270)"
          >
            {box.label}
          </text>
          <text
            x={box.x + 90}
            y={86}
            text-anchor="middle"
            font-size="11.5"
            fill="oklch(0.43 0.012 270)"
          >
            {box.sub}
          </text>
          {index < boxes.length - 1 ? (
            <g>
              <line
                x1={box.x + 180}
                y1={68}
                x2={box.x + 220}
                y2={68}
                stroke="oklch(0.55 0.26 296)"
                stroke-width={2}
              />
              <polygon
                points={`${box.x + 220},68 ${box.x + 212},63 ${box.x + 212},73`}
                fill="oklch(0.55 0.26 296)"
              />
            </g>
          ) : null}
        </g>
      ))}
      <text x={200} y={132} text-anchor="middle" font-size="11.5" fill="oklch(0.55 0.012 270)">
        consent snapshot on every batch
      </text>
      <text x={440} y={132} text-anchor="middle" font-size="11.5" fill="oklch(0.55 0.012 270)">
        refuses unconsented items
      </text>
      <text x={660} y={132} text-anchor="middle" font-size="11.5" fill="oklch(0.55 0.012 270)">
        read-only reporting role
      </text>
    </svg>
  </div>
);

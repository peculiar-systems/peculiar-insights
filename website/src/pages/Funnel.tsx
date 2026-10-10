import { useEffect, useRef } from "preact/hooks";
import { visuallyHidden } from "../app/global.css.ts";
import * as s from "./pages.css.ts";

/*
 * Visitors pour into a funnel whose only exit is plugged by the 404. It fills, the
 * drop-off reads 100%, it drains, and it starts again. Nobody ever reaches the page.
 */

type Cell = { ch: string; cls: string };
type Grid = Cell[][];

const W = 62;
const H = 19;
const NECK = 15;
const PLUG = 18;
const SIDE = 42;
const TICK = 60;
const MODULUS = 2_147_483_647;

const left = (y: number): number => (y < NECK ? 2 + y : 16);
const right = (y: number): number => (y < NECK ? 37 - y : 23);
const inside = (x: number, y: number): boolean => y >= 0 && y < PLUG && x > left(y) && x < right(y);

let capacity = 0;
for (let y = 0; y < PLUG; y += 1) {
  capacity += right(y) - left(y) - 1;
}

type Sim = {
  sand: Uint8Array;
  moved: Uint8Array;
  seed: number;
  opened: number;
  full: number;
  draining: boolean;
  tick: number;
};

const random = (sim: Sim): number => {
  sim.seed = (sim.seed * 48_271) % MODULUS;
  return sim.seed / MODULUS;
};

const at = (x: number, y: number): number => y * W + x;

const fresh = (seed: number): Sim => ({
  sand: new Uint8Array(W * H),
  moved: new Uint8Array(W * H),
  seed: (seed % (MODULUS - 1)) + 1,
  opened: 0,
  full: 0,
  draining: false,
  tick: 0,
});

const free = (sim: Sim, x: number, y: number): boolean => inside(x, y) && sim.sand[at(x, y)] === 0;

const move = (sim: Sim, from: number, to: number): void => {
  sim.sand[from] = 0;
  sim.sand[to] = 1;
  sim.moved[to] = 1;
};

const fall = (sim: Sim): void => {
  sim.moved.fill(0);
  for (let y = PLUG - 1; y >= 0; y -= 1) {
    const flip = random(sim) < 0.5;
    for (let i = 0; i < W; i += 1) {
      const x = flip ? i : W - 1 - i;
      if (sim.sand[at(x, y)] === 1 && sim.moved[at(x, y)] === 0) {
        const side = random(sim) < 0.5 ? -1 : 1;
        const down = [x, x + side, x - side].find((nx) => free(sim, nx, y + 1));
        // The walls are as steep as a sand pile, so grains slide inwards along them.
        const inward = x < (left(y) + right(y)) / 2 ? 1 : -1;
        if (down !== undefined) {
          move(sim, at(x, y), at(down, y + 1));
        } else if (random(sim) < 0.5 && free(sim, x + inward, y)) {
          move(sim, at(x, y), at(x + inward, y));
        }
      }
    }
  }
};

const drain = (sim: Sim): void => {
  let remaining = 0;
  for (let i = 0; i < sim.sand.length; i += 1) {
    if (sim.sand[i] === 1 && random(sim) < 0.14) {
      sim.sand[i] = 0;
    }
    remaining += sim.sand[i] ?? 0;
  }
  if (remaining === 0) {
    sim.draining = false;
    sim.full = 0;
  }
};

const step = (sim: Sim): void => {
  sim.tick += 1;
  if (sim.draining) {
    drain(sim);
    return;
  }
  fall(sim);
  if (sim.full > 0) {
    sim.full += 1;
    sim.draining = sim.full > 50;
    return;
  }
  for (let n = 0; n < 2; n += 1) {
    const x = left(0) + 1 + Math.floor(random(sim) * (right(0) - left(0) - 1));
    if (free(sim, x, 0)) {
      sim.sand[at(x, 0)] = 1;
      sim.opened += 1;
    }
  }
  const filled = sim.sand.reduce((sum, grain) => sum + grain, 0);
  if (filled > capacity * 0.9) {
    sim.full = 1;
  }
};

const put = (grid: Grid, x: number, y: number, text: string, cls = ""): void => {
  for (let i = 0; i < text.length; i += 1) {
    const cell = grid[y]?.[x + i];
    if (cell !== undefined) {
      cell.ch = text.charAt(i);
      cell.cls = cls;
    }
  }
};

const grain = (sim: Sim, x: number, y: number): readonly [string, string] => {
  if (sim.moved[at(x, y)] === 1) {
    return [".", "v"];
  }
  if (y === 0 || sim.sand[at(x, y - 1)] === 0) {
    return ["o", "v"];
  }
  return [":", "d"];
};

const draw = (sim: Sim): Grid => {
  const grid = Array.from({ length: H }, () =>
    Array.from({ length: W }, (): Cell => ({ ch: " ", cls: "" })),
  );
  for (let y = 0; y < PLUG; y += 1) {
    put(grid, left(y), y, y < NECK ? "\\" : "|", "d");
    put(grid, right(y), y, y < NECK ? "/" : "|", "d");
    for (let x = left(y) + 1; x < right(y); x += 1) {
      if (sim.sand[at(x, y)] === 1) {
        const [ch, cls] = grain(sim, x, y);
        put(grid, x, y, ch, cls);
      }
    }
  }
  put(grid, 16, PLUG, "'[404]-'", "m");

  put(grid, SIDE, 1, "opened a link", "d");
  put(grid, SIDE, 2, String(sim.opened).padStart(6), "l");
  put(grid, SIDE, 7, "found the page", "d");
  put(grid, SIDE, 8, "     0  ________", "b");
  put(grid, SIDE, 12, "conversion", "d");
  put(grid, SIDE, 13, "  0.0%", "b");
  if (sim.full > 0 && Math.floor(sim.tick / 6) % 2 === 0) {
    put(grid, SIDE, 17, "drop-off: 100%", "m");
  }
  return grid;
};

const escape = (ch: string): string =>
  ch.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;");

const html = (grid: Grid): string =>
  grid
    .map((row) => {
      let out = "";
      let open = "";
      for (const cell of row) {
        if (cell.cls !== open) {
          out += open === "" ? "" : "</span>";
          out += cell.cls === "" ? "" : `<span class="${cell.cls}">`;
          open = cell.cls;
        }
        out += escape(cell.ch);
      }
      return open === "" ? out : `${out}</span>`;
    })
    .join("\n");

const still = (): string => {
  const sim = fresh(404);
  for (let i = 0; i < 160; i += 1) {
    step(sim);
  }
  return html(draw(sim));
};

export const Funnel = () => {
  const ref = useRef<HTMLPreElement>(null);
  useEffect(() => {
    if (globalThis.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      return undefined;
    }
    const sim = fresh(Date.now());
    const timer = setInterval(() => {
      step(sim);
      if (ref.current !== null) {
        ref.current.innerHTML = html(draw(sim));
      }
    }, TICK);
    return () => {
      clearInterval(timer);
    };
  }, []);
  return (
    <>
      <pre
        ref={ref}
        class={s.wire}
        style={{ fontSize: `min(13.5px, calc((100vw - 92px) / ${W * 0.6}))` }}
        aria-hidden="true"
        dangerouslySetInnerHTML={{ __html: still() }}
      />
      <p class={visuallyHidden}>
        A funnel: everyone opened a link, nobody found the page. Conversion 0%, drop-off 100%.
      </p>
    </>
  );
};

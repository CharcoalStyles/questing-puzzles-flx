import { z } from "zod";
import {mana} from "./General.ts";

export const Spell = z.object({
  name: z.string(),
  description: z.string(),
  mana: z.record(mana, z.number()),
  effect: z.string(),
  args: z.record(
    z.union([
      z.string(),
      z.number(),
      z.boolean(),
      z.record(
        z.union([
          z.string(),
          z.number(),
          z.boolean(),
        ]),
      ),
    ]),
  ),
});

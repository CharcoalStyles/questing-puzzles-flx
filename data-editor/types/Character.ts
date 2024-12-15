import { z } from "zod";
import { mana } from "./General.ts";

export const character = z.object({
  name: z.string(),
  level: z.number(),
  health: z.number(),
  mana: z.record(mana, z.number()),
  spells: z.array(z.string()),
});

export type Character = z.infer<typeof character>;

import { z } from "zod";

export const mana = z.union([
  z.literal('Fire'),
  z.literal('Dark'),
  z.literal('Water'),
  z.literal('Light'),
  z.literal('Earth'),
]);

export type Mana = z.infer<typeof mana>;

export const script = z.record(z.string(), z.string());

export type Script = z.infer<typeof script>;
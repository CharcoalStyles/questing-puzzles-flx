import { z } from "zod";

export const fileType = z.union([
  z.literal('character'),
  z.literal('effect'),
  z.literal('spell'),
]);

export type FileType = z.infer<typeof fileType>;

export const mana = z.union([
  z.literal('Fire'),
  z.literal('Dark'),
  z.literal('Water'),
  z.literal('Light'),
  z.literal('Earth'),
]);

export type Mana = z.infer<typeof mana>;
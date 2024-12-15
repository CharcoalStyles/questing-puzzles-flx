// Next.js API route support: https://nextjs.org/docs/api-routes/introduction
import type { NextApiRequest, NextApiResponse } from "next";
import join from "path.join";

type Data =  Array<Spell>;

type Spell = {
  name: string
  description: string
  mana: Mana
  effect: string
  args: Record<string, string | number | boolean | Lifespan>
}

type Mana = {
  Fire: number
  Dark: number
  Water: number
  Light: number
  Earth: number
}

type Lifespan = {
  min: number
  max: number
}



export default async function handler(
  _req: NextApiRequest,
  res: NextApiResponse<Data>,
) {
  const spells:Array<Spell> = [];
  // list all the files in the spells directory
  for await (const dirEntry of Deno.readDir(join(Deno.cwd(), "../assets/data/spells"))) {
    console.log(dirEntry.name);
    const spell = await Deno.readTextFile(join(Deno.cwd(), "../assets/data/spells", dirEntry.name));
    spells.push(JSON.parse(spell));
   }
   
  res.status(200).json(spells);
}

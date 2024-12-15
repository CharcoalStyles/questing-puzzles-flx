// Next.js API route support: https://nextjs.org/docs/api-routes/introduction
import type { NextApiRequest, NextApiResponse } from "next";
import join from "path.join";

type Data =  Record<string, string>;

export default async function handler(
  _req: NextApiRequest,
  res: NextApiResponse<Data>,
) {
  const effects:Record<string, string> = {};
  // list all the files in the spells directory
  for await (const dirEntry of Deno.readDir(join(Deno.cwd(), "../assets/data/effects"))) {
    console.log(dirEntry.name);
    const effect = await Deno.readTextFile(join(Deno.cwd(), "../assets/data/effects", dirEntry.name));
    effects[dirEntry.name.split('.')[0]] = effect;
   }
   
  res.status(200).json(effects);
}

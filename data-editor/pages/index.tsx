
import { fetchFetcher } from "@/lib/useFetcher";
import useSWR from "swr";

export default function Home() {

  const { data, error, isValidating } = useSWR('/api/spells', fetchFetcher);

  return (
    <div >
      <h1 className="text-5xl font-bold text-white font-sans">Questing Puzzles - Data Editor</h1>
    </div>
  );
}

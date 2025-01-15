import useSWR from 'swr'

// Define a custom fetcher function using the native fetch API
export const fetchFetcher = async (url: string): Promise<any> => {
  const res = await fetch(url);
  if (!res.ok) {
    throw new Error('Network response was not ok');
  }
  return res.json();
};

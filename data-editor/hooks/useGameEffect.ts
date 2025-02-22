import { useState, useEffect } from 'react';
import axios from 'axios';
import {Effect} from "../types/Effects.ts"

export const useGameEffect = (url: string) => {
  const [data, setData] = useState<Effect[]>([]);
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        const response = await axios.get<Effect[]>(url);
        setData(response.data);
      } catch (err) {
        if (axios.isAxiosError(err)) {
          setError(err.message);
        } else {
          setError('An unexpected error occurred');
        }
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [url]);

  const createItem = async (name:string, newItem: Effect) => {
    try {
      await axios.post<Effect>(url, newItem);
      // Optionally refresh the data after creation
      const response = await axios.get<Effect[]>(url);
      setData(response.data);
    } catch (err) {
      if (axios.isAxiosError(err)) {
        setError(err.message);
      } else {
        setError('An unexpected error occurred');
      }
    }
  };

  const updateItem = async (name:string, updatedItem: Effect) => {
    try {
      await axios.put<Effect>(`${url}/${name}`, updatedItem);
      // Optionally refresh the data after update
      const response = await axios.get<Effect[]>(url);
      setData(response.data);
    } catch (err) {
      if (axios.isAxiosError(err)) {
        setError(err.message);
      } else {
        setError('An unexpected error occurred');
      }
    }
  };

  const deleteItem = async (id: number) => {
    try {
      await axios.delete<Effect>(`${url}/${id}`);
      // Optionally refresh the data after deletion
      const response = await axios.get<Effect[]>(url);
      setData(response.data);
    } catch (err) {
      if (axios.isAxiosError(err)) {
        setError(err.message);
      } else {
        setError('An unexpected error occurred');
      }
    }
  };

  return { data, loading, error, createItem, updateItem, deleteItem };
};
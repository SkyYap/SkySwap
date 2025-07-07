'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ThemeProvider } from 'next-themes';
import { useState, useEffect } from 'react';
import dynamic from 'next/dynamic';

// Dynamically import wallet providers to prevent SSR hydration issues
const WalletProviders = dynamic(
  () => import('./wallet-providers').then((mod) => mod.WalletProviders),
  { ssr: false }
);

export function Providers({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(() => new QueryClient());
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  return (
    <ThemeProvider attribute="class" defaultTheme="dark" enableSystem>
      <QueryClientProvider client={queryClient}>
        {mounted ? (
          <WalletProviders>{children}</WalletProviders>
        ) : (
          <div suppressHydrationWarning>{children}</div>
        )}
      </QueryClientProvider>
    </ThemeProvider>
  );
}
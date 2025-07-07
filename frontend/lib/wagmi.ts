import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { mainnet, polygon, arbitrum, base } from 'wagmi/chains';

export const wagmiConfig = getDefaultConfig({
  appName: 'SkySwap AMM',
  projectId: process.env.NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID || 'demo',
  chains: [mainnet, polygon, arbitrum, base],
  ssr: false,
});
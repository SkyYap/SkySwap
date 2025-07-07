'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { SwapInterface } from '@/components/swap/swap-interface';

export default function Swap() {
  return (
    <div className="container mx-auto px-4 py-8 flex flex-col items-center justify-center min-h-[70vh]">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        className="mb-8"
      >
        <h1 className="text-3xl font-bold text-white mb-2">Swap</h1>
        <p className="text-gray-400">Trade tokens with optimal pricing and minimal slippage</p>
      </motion.div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.1 }}
        className="w-full max-w-lg"
      >
        <SwapInterface />
      </motion.div>
    </div>
  );
}
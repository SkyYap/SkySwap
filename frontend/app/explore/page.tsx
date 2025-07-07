'use client';

import { motion } from 'framer-motion';
import { ProtocolOverview } from '@/components/explore/protocol-overview';
import { PoolsTable } from '@/components/explore/pools-table';

export default function Explore() {
  return (
    <div className="container mx-auto px-4 py-8 space-y-8">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
      >
        <h1 className="text-3xl font-bold text-white mb-2">Explore</h1>
        <p className="text-gray-400">Discover pools and protocol metrics</p>
      </motion.div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.1 }}
      >
        <ProtocolOverview />
      </motion.div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.2 }}
      >
        <PoolsTable />
      </motion.div>
    </div>
  );
}
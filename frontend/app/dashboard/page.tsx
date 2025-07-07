'use client';

import { motion } from 'framer-motion';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { ActivityHistory } from '@/components/dashboard/activity-history';
import { LiquidityPositions } from '@/components/dashboard/liquidity-positions';
import { RewardsOverview } from '@/components/dashboard/rewards-overview';
import { ReferralEarnings } from '@/components/dashboard/referral-earnings';

export default function Dashboard() {
  return (
    <div className="container mx-auto px-4 py-8">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        className="mb-8"
      >
        <h1 className="text-3xl font-bold text-white mb-2">Dashboard</h1>
        <p className="text-gray-400">Monitor your portfolio and trading activity</p>
      </motion.div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.1 }}
      >
        <Tabs defaultValue="positions" className="space-y-6">
          <TabsList className="grid w-full grid-cols-4 bg-black/20 border-white/10">
            <TabsTrigger value="positions">Positions</TabsTrigger>
            <TabsTrigger value="activity">Activity</TabsTrigger>
            <TabsTrigger value="referral">Referral</TabsTrigger>
            <TabsTrigger value="rewards">Rewards</TabsTrigger>
          </TabsList>

          <TabsContent value="positions" className="space-y-6">
            <LiquidityPositions />
          </TabsContent>
          
          <TabsContent value="activity" className="space-y-6">
            <ActivityHistory />
          </TabsContent>
          
          <TabsContent value="referral" className="space-y-6">
            <ReferralEarnings />
          </TabsContent>
          
          <TabsContent value="rewards" className="space-y-6">
            <RewardsOverview />
          </TabsContent>
        </Tabs>
      </motion.div>
    </div>
  );
}
'use client';

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Gift } from 'lucide-react';

export function ReferralEarnings() {
  // Placeholder value for referral earnings
  const earnings = '$123.45';
  // Placeholder referral data
  const referrals = [
    { address: '0xA1B2...C3D4', date: '2025-06-01', amount: '$25.00' },
    { address: '0xE5F6...G7H8', date: '2025-06-20', amount: '$50.00' },
    { address: '0xI9J0...K1L2', date: '2025-07-05', amount: '$48.45' },
  ];

  return (
    <Card className="bg-black/20 border-white/10 backdrop-blur-sm">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-white">
          <Gift className="w-5 h-5" />
          Referral Earnings
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="flex flex-col items-center justify-center py-8 w-full">
          <div className="text-4xl font-bold text-green-400 mb-2">{earnings}</div>
          <div className="text-gray-400 mb-4">Total earned from referrals</div>
          <div className="text-white font-semibold mb-2">{referrals.length} Referrals</div>
          {/* Referral List Header */}
          <div className="grid grid-cols-3 gap-4 text-sm text-gray-400 font-medium border-b border-white/10 pb-2 w-full max-w-2xl mx-auto">
            <div>Address</div>
            <div>Date</div>
            <div className="text-right">Amount</div>
          </div>
          {/* Referral List Rows */}
          <div className="w-full max-w-2xl mx-auto">
            {referrals.map((ref, idx) => (
              <div
                key={idx}
                className="grid grid-cols-3 gap-4 items-center p-3 rounded-lg bg-white/5 hover:bg-white/10 transition-colors mt-2"
              >
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
                    <span className="text-white text-xs font-semibold">
                      {ref.address.slice(2, 4)}{ref.address.slice(-4, -2)}
                    </span>
                  </div>
                  <span className="font-semibold text-white">{ref.address}</span>
                </div>
                <div className="text-gray-400">{ref.date}</div>
                <div className="text-green-400 font-medium text-right">{ref.amount}</div>
              </div>
            ))}
          </div>
        </div>
      </CardContent>
    </Card>
  );
} 
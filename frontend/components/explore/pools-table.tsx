'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Search, ArrowUpDown, TrendingUp, TrendingDown, Droplets } from 'lucide-react';

const pools = [
  {
    pair: 'ETH/USDC',
    tvl: '$12.4M',
    apy: '24.5%',
    volume24h: '$1.9M',
    fees24h: '$5,700',
    participants: 847,
    ilProtected: true,
    change: '+2.4%',
    positive: true
  },
  {
    pair: 'WBTC/ETH',
    tvl: '$8.9M',
    apy: '18.7%',
    volume24h: '$1.2M',
    fees24h: '$3,600',
    participants: 623,
    ilProtected: true,
    change: '-1.2%',
    positive: false
  },
  {
    pair: 'UNI/USDC',
    tvl: '$4.2M',
    apy: '32.1%',
    volume24h: '$800K',
    fees24h: '$2,400',
    participants: 412,
    ilProtected: false,
    change: '+5.7%',
    positive: true
  },
  {
    pair: 'LINK/ETH',
    tvl: '$3.8M',
    apy: '28.9%',
    volume24h: '$650K',
    fees24h: '$1,950',
    participants: 298,
    ilProtected: true,
    change: '+3.1%',
    positive: true
  },
  {
    pair: 'AAVE/USDC',
    tvl: '$2.1M',
    apy: '41.2%',
    volume24h: '$420K',
    fees24h: '$1,260',
    participants: 156,
    ilProtected: false,
    change: '+8.9%',
    positive: true
  }
];

export function PoolsTable() {
  const [searchTerm, setSearchTerm] = useState('');
  const [sortBy, setSortBy] = useState('tvl');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc');

  const filteredPools = pools
    .filter(pool => 
      pool.pair.toLowerCase().includes(searchTerm.toLowerCase())
    )
    .sort((a, b) => {
      let aValue, bValue;
      
      switch (sortBy) {
        case 'tvl':
          aValue = parseFloat(a.tvl.replace(/[$M]/g, ''));
          bValue = parseFloat(b.tvl.replace(/[$M]/g, ''));
          break;
        case 'apy':
          aValue = parseFloat(a.apy.replace('%', ''));
          bValue = parseFloat(b.apy.replace('%', ''));
          break;
        case 'volume':
          aValue = parseFloat(a.volume24h.replace(/[$MK]/g, ''));
          bValue = parseFloat(b.volume24h.replace(/[$MK]/g, ''));
          break;
        default:
          return 0;
      }
      
      return sortOrder === 'desc' ? bValue - aValue : aValue - bValue;
    });

  const handleSort = (field: string) => {
    if (sortBy === field) {
      setSortOrder(sortOrder === 'desc' ? 'asc' : 'desc');
    } else {
      setSortBy(field);
      setSortOrder('desc');
    }
  };

  return (
    <Card className="bg-black/20 border-white/10 backdrop-blur-sm">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-white">
          <Droplets className="w-5 h-5" />
          Liquidity Pools
        </CardTitle>
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
            <Input
              placeholder="Search pools..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-10"
            />
          </div>
          <Select value={sortBy} onValueChange={setSortBy}>
            <SelectTrigger className="w-48">
              <SelectValue placeholder="Sort by" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="tvl">Total Value Locked</SelectItem>
              <SelectItem value="apy">APY</SelectItem>
              <SelectItem value="volume">24h Volume</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {/* Table Header */}
          <div className="grid grid-cols-7 gap-4 text-sm text-gray-400 font-medium border-b border-white/10 pb-2">
            <div>Pool</div>
            <div className="cursor-pointer flex items-center gap-1" onClick={() => handleSort('tvl')}>
              TVL <ArrowUpDown className="w-3 h-3" />
            </div>
            <div className="cursor-pointer flex items-center gap-1" onClick={() => handleSort('apy')}>
              APY <ArrowUpDown className="w-3 h-3" />
            </div>
            <div className="cursor-pointer flex items-center gap-1" onClick={() => handleSort('volume')}>
              24h Volume <ArrowUpDown className="w-3 h-3" />
            </div>
            <div>24h Change</div>
            <div>IL Protection</div>
            <div>Action</div>
          </div>

          {/* Table Rows */}
          {filteredPools.map((pool, index) => (
            <motion.div
              key={pool.pair}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.3, delay: index * 0.05 }}
              className="grid grid-cols-7 gap-4 items-center p-3 rounded-lg bg-white/5 hover:bg-white/10 transition-colors"
            >
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
                  <span className="text-white text-xs font-semibold">
                    {pool.pair.split('/')[0].slice(0, 1)}{pool.pair.split('/')[1].slice(0, 1)}
                  </span>
                </div>
                <div>
                  <div className="font-semibold text-white">{pool.pair}</div>
                  <div className="text-xs text-gray-400">{pool.participants} LPs</div>
                </div>
              </div>
              
              <div className="text-white font-medium">{pool.tvl}</div>
              
              <div className="text-green-400 font-medium">{pool.apy}</div>
              
              <div className="text-white">{pool.volume24h}</div>
              
              <div className={`flex items-center gap-1 ${pool.positive ? 'text-green-400' : 'text-red-400'}`}>
                {pool.positive ? <TrendingUp className="w-3 h-3" /> : <TrendingDown className="w-3 h-3" />}
                {pool.change}
              </div>
              
              <div>
                {pool.ilProtected ? (
                  <Badge variant="default" className="bg-green-500/20 text-green-400 border-green-500/30">
                    Protected
                  </Badge>
                ) : (
                  <Badge variant="outline" className="text-gray-400">
                    Standard
                  </Badge>
                )}
              </div>
              
              <div>
                <Button size="sm" className="bg-blue-600 hover:bg-blue-700">
                  Add Liquidity
                </Button>
              </div>
            </motion.div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}
'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Switch } from '@/components/ui/switch';
import { Slider } from '@/components/ui/slider';
import { Droplets, Shield, Info, AlertTriangle } from 'lucide-react';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';

const pools = [
  { pair: 'ETH/USSKY', apy: '24.5%', tvl: '$12.4M', ilProtected: true },
  { pair: 'BTC/USSKY', apy: '18.7%', tvl: '$8.9M', ilProtected: true },
  { pair: 'UNI/USSKY', apy: '32.1%', tvl: '$4.2M', ilProtected: false },
  { pair: 'LINK/USSKY', apy: '28.9%', tvl: '$3.8M', ilProtected: true },
  { pair: 'AAVE/USSKY', apy: '41.2%', tvl: '$2.1M', ilProtected: false },
];

interface LiquidityInterfaceProps {
  selectedPool: string;
}

export function LiquidityInterface({ selectedPool }: LiquidityInterfaceProps) {
  const [amount, setAmount] = useState('');
  const [enableHedging, setEnableHedging] = useState(false);
  const [ethExposure, setEthExposure] = useState([70]);
  const [leverage, setLeverage] = useState([3]);

  const currentPool = pools.find(p => p.pair === selectedPool) || pools[0];
  const expectedAPY = currentPool?.apy || '24.5%';
  const poolShare = '0.12%';
  const expectedFees = '$15.20/day';

  // Calculate required USDC based on amount, exposure, and leverage
  const calculateRequiredUSDC = () => {
    if (!amount) return '0.00';
    const amountNum = parseFloat(amount);
    const exposureRatio = ethExposure[0] / 100;
    const leverageRatio = leverage[0];
    const ethPrice = 2500; // Mock ETH price
    
    const requiredUSDC = (amountNum * ethPrice * exposureRatio) / leverageRatio;
    return requiredUSDC.toFixed(2);
  };

  // Calculate liquidation price
  const calculateLiquidationPrice = () => {
    if (!amount) return '$0.00';
    const leverageRatio = leverage[0];
    const ethPrice = 2500; // Mock ETH price
    const liquidationPrice = ethPrice * (1 - 0.8 / leverageRatio);
    return `$${liquidationPrice.toFixed(2)}`;
  };

  // Calculate funding rate
  const calculateFundingRate = () => {
    const baseRate = 0.01; // 1% base
    const leverageMultiplier = leverage[0] * 0.005; // 0.5% per leverage
    return ((baseRate + leverageMultiplier) * 100).toFixed(3);
  };

  const handleAddLiquidity = () => {
    console.log('Adding liquidity:', amount, selectedPool, {
      hedging: enableHedging,
      ethExposure: ethExposure[0],
      leverage: leverage[0]
    });
  };

  return (
    <Card className="bg-black/20 border-white/10 backdrop-blur-sm">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-white">
          <Droplets className="w-5 h-5" />
          Add Liquidity
        </CardTitle>
      </CardHeader>
      <CardContent className="p-0">
        <div className="flex flex-col md:flex-row">
          {/* Left Side */}
          <div className={`p-6 space-y-4 ${enableHedging ? 'flex-1' : 'w-full md:max-w-lg'} md:pl-8 md:max-w-lg `}>
            {/* Amount Input */}
            <div className="p-4 bg-white/5 rounded-lg">
              <div className="flex justify-between items-center mb-2">
                <span className="text-sm text-gray-400">Amount (ETH)</span>
                <span className="text-sm text-gray-400">
                  Balance: 8,420.00
                </span>
              </div>
              <div className="flex gap-2">
                <Input
                  placeholder="0.0"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  className="flex-1"
                />
                <Button variant="outline" size="sm">
                  Max
                </Button>
              </div>
            </div>

            {/* IL Hedging Toggle */}
            <div className="p-4 bg-white/5 rounded-lg">
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-2">
                  <Shield className="w-4 h-4 text-green-400" />
                  <span className="text-white font-medium">IL Hedging</span>
                  <TooltipProvider>
                    <Tooltip>
                      <TooltipTrigger>
                        <Info className="w-3 h-3 text-gray-400" />
                      </TooltipTrigger>
                      <TooltipContent>
                        <p>Eliminates impermanent loss through automated hedging</p>
                      </TooltipContent>
                    </Tooltip>
                  </TooltipProvider>
                </div>
                <Switch
                  checked={enableHedging}
                  onCheckedChange={setEnableHedging}
                />
              </div>
              <div className="text-sm text-gray-400">
                Enable automated hedging to eliminate impermanent loss risk
              </div>
            </div>

            <Button
              onClick={handleAddLiquidity}
              className="w-full bg-blue-600 hover:bg-blue-700"
              disabled={!amount}
            >
              {!amount ? 'Enter Amount' : 'Add Liquidity'}
            </Button>
          </div>

          {/* Right Side: Advanced Hedging, only if enabled */}
          {enableHedging && (
            <div className="flex-1 p-6 border-t md:border-t-0 md:border-l border-white/10 bg-blue-500/5 space-y-6">
              {/* Advanced Hedging Configuration */}
              <div className="flex items-center gap-2 mb-4">
                <Shield className="w-5 h-5 text-blue-400" />
                <span className="text-blue-400 font-medium">Advanced Hedging Configuration</span>
              </div>

              {/* ETH Exposure Slider */}
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <span className="text-white font-medium">ETH Exposure Coverage</span>
                    <TooltipProvider>
                      <Tooltip>
                        <TooltipTrigger>
                          <Info className="w-3 h-3 text-gray-400" />
                        </TooltipTrigger>
                        <TooltipContent>
                          <p>Percentage of ETH exposure to hedge against price movements</p>
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>
                  </div>
                  <Badge variant="outline">{ethExposure[0]}%</Badge>
                </div>
                <Slider
                  value={ethExposure}
                  onValueChange={setEthExposure}
                  max={100}
                  min={0}
                  step={5}
                  className="w-full"
                />
                <div className="flex justify-between text-xs text-gray-400">
                  <span>0%</span>
                  <span>50%</span>
                  <span>100%</span>
                </div>
              </div>

              {/* Leverage Slider */}
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-white font-medium">Leverage Ratio</span>
                  <Badge variant={leverage[0] > 5 ? "destructive" : "default"}>
                    {leverage[0]}x
                  </Badge>
                </div>
                <Slider
                  value={leverage}
                  onValueChange={setLeverage}
                  max={10}
                  min={1}
                  step={1}
                  className="w-full"
                />
                <div className="flex justify-between text-xs text-gray-400">
                  <span>1x</span>
                  <span>5x</span>
                  <span>10x</span>
                </div>
              </div>

              {/* Required USDC Display */}
              <div className="p-3 bg-white/5 rounded-lg">
                <div className="flex justify-between items-center">
                  <span className="text-gray-400">Required USDC Collateral</span>
                  <span className="text-white font-semibold">{calculateRequiredUSDC()} USDC</span>
                </div>
              </div>

              {/* Risk Metrics */}
              <div className="space-y-3 p-3 bg-red-500/10 border border-red-500/20 rounded-lg">
                <div className="flex items-center gap-2 mb-2">
                  <AlertTriangle className="w-4 h-4 text-red-400" />
                  <span className="text-red-400 font-medium">Risk Metrics</span>
                </div>
                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div className="flex justify-between">
                    <span className="text-gray-400">Liquidation Price</span>
                    <span className="text-red-400">{calculateLiquidationPrice()}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-400">Leverage Ratio</span>
                    <span className="text-white">{leverage[0]}x</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-400">ETH Coverage</span>
                    <span className="text-white">{ethExposure[0]}%</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-400">Funding Rate</span>
                    <span className="text-white">{calculateFundingRate()}%</span>
                  </div>
                </div>
              </div>

              {/* High Leverage Warning */}
              {leverage[0] > 5 && (
                <motion.div
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  className="p-3 bg-yellow-500/10 border border-yellow-500/20 rounded-lg"
                >
                  <div className="flex items-center gap-2 mb-2">
                    <AlertTriangle className="w-4 h-4 text-yellow-400" />
                    <span className="text-yellow-400 font-medium">High Leverage Warning</span>
                  </div>
                  <div className="text-sm text-gray-400">
                    High leverage increases liquidation risk. Consider reducing leverage for safer trading.
                  </div>
                </motion.div>
              )}
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  );
}
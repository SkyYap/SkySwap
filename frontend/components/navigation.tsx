'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { motion } from 'framer-motion';
import dynamic from 'next/dynamic';
import { 
  BarChart3, 
  ArrowLeftRight, 
  Droplets, 
  Menu,
  X,
  Sun,
  Moon,
  TrendingUp,
  Compass
} from 'lucide-react';
import { useTheme } from 'next-themes';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';

// Dynamically import ConnectButton to prevent hydration issues
const ConnectButton = dynamic(
  () => import('@rainbow-me/rainbowkit').then((mod) => ({ default: mod.ConnectButton })),
  { ssr: false }
);

const navItems = [
  { name: 'Dashboard', href: '/dashboard', icon: BarChart3 },
  { name: 'Swap', href: '/swap', icon: ArrowLeftRight },
  { name: 'Add Liquidity', href: '/add-liquidity', icon: Droplets },
  { name: 'Explore', href: '/explore', icon: Compass },
];

export function Navigation() {
  const [isOpen, setIsOpen] = useState(false);
  const [mounted, setMounted] = useState(false);
  const { theme, setTheme } = useTheme();
  const pathname = usePathname();

  useEffect(() => {
    setMounted(true);
  }, []);

  return (
    <nav className="fixed top-0 left-0 right-0 z-50 bg-black/20 backdrop-blur-lg border-b border-white/10">
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <Link href="/" className="flex items-center space-x-2">
            <div className="w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg flex items-center justify-center">
              <TrendingUp className="w-5 h-5 text-white" />
            </div>
            <span className="text-xl font-bold text-white">SkySwap</span>
          </Link>

          {/* Desktop Navigation */}
          <div className="hidden md:flex items-center space-x-8">
            {navItems.map((item) => {
              const Icon = item.icon;
              const isActive = pathname === item.href;
              
              return (
                <Link key={item.name} href={item.href} className="relative">
                  <div className={cn(
                    "flex items-center space-x-2 px-4 py-2 rounded-lg transition-all duration-200",
                    isActive 
                      ? "text-blue-400 bg-blue-500/20" 
                      : "text-gray-300 hover:text-white hover:bg-white/10"
                  )}>
                    <Icon className="w-4 h-4" />
                    <span className="font-medium">{item.name}</span>
                  </div>
                  {isActive && (
                    <motion.div
                      layoutId="activeTab"
                      className="absolute -bottom-1 left-0 right-0 h-0.5 bg-blue-400 rounded-full"
                    />
                  )}
                </Link>
              );
            })}
          </div>

          {/* Right side actions */}
          <div className="flex items-center space-x-4">
            {/* TODO: Add theme toggle back in if want dark mod/ light mode switching */}
            {/* {mounted && (
              <Button
                variant="ghost"
                size="icon"
                onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
                className="text-gray-300 hover:text-white"
              >
                {theme === 'dark' ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
              </Button>
            )} */}
            
            <div className="hidden md:block">
              <ConnectButton showBalance={false} />
            </div>

            {/* Mobile menu button */}
            <Button
              variant="ghost"
              size="icon"
              className="md:hidden text-gray-300 hover:text-white"
              onClick={() => setIsOpen(!isOpen)}
            >
              {isOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </Button>
          </div>
        </div>

        {/* Mobile Navigation */}
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            className="md:hidden border-t border-white/10 py-4"
          >
            <div className="flex flex-col space-y-2">
              {navItems.map((item) => {
                const Icon = item.icon;
                const isActive = pathname === item.href;
                
                return (
                  <Link 
                    key={item.name} 
                    href={item.href}
                    onClick={() => setIsOpen(false)}
                    className={cn(
                      "flex items-center space-x-2 px-4 py-3 rounded-lg transition-all duration-200",
                      isActive 
                        ? "text-blue-400 bg-blue-500/20" 
                        : "text-gray-300 hover:text-white hover:bg-white/10"
                    )}
                  >
                    <Icon className="w-4 h-4" />
                    <span className="font-medium">{item.name}</span>
                  </Link>
                );
              })}
              <div className="pt-4 border-t border-white/10">
                <ConnectButton showBalance={false} />
              </div>
            </div>
          </motion.div>
        )}
      </div>
    </nav>
  );
}
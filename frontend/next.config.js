/** @type {import('next').NextConfig} */
const nextConfig = {
  // output: 'export',
  eslint: {
    ignoreDuringBuilds: true,
  },
  images: { unoptimized: true },
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'Cross-Origin-Opener-Policy',
            value: 'same-origin-allow-popups',
          },
        ],
      },
    ];
  },
  webpack: (config) => {
    config.module.rules.push({
      test: /HeartbeatWorker\.js$/,
      type: 'javascript/auto',
    });
    if (typeof config.webpack === 'function') {
      return config.webpack(config);
    }
    return config;
  },
};

module.exports = nextConfig;
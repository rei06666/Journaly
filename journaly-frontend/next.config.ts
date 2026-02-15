import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Static export for S3 + CloudFront deployment
  output: 'export',
  
  // Disable image optimization for static export
  images: {
    unoptimized: true,
  },
  
  // Optional: Add trailing slashes for better S3 compatibility
  trailingSlash: true,
};

export default nextConfig;

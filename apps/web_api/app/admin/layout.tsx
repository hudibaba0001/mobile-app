import { Metadata } from 'next';
import '../globals.css';

export const metadata: Metadata = {
  title: 'KvikTime Admin',
  description: 'Administrative dashboard for KvikTime',
};

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}

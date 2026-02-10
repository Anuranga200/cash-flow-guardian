import { Cheque, Supplier, BankAccount, Notification, MLForecast } from '@/types';

export const suppliers: Supplier[] = [
  { id: 's1', company: 'Gupta Steel Works', contactPerson: 'Rajesh Gupta', phone: '+91 98765 43210', email: 'rajesh@guptasteel.com', paymentTermsDays: 30 },
  { id: 's2', company: 'Sharma Electricals', contactPerson: 'Amit Sharma', phone: '+91 98765 43211', email: 'amit@sharmaelec.com', paymentTermsDays: 15 },
  { id: 's3', company: 'Patel Logistics', contactPerson: 'Nitin Patel', phone: '+91 98765 43212', email: 'nitin@patellog.com', paymentTermsDays: 45 },
  { id: 's4', company: 'Kumar Chemicals', contactPerson: 'Suresh Kumar', phone: '+91 98765 43213', email: 'suresh@kumarchem.com', paymentTermsDays: 30 },
  { id: 's5', company: 'Singh Hardware', contactPerson: 'Harpreet Singh', phone: '+91 98765 43214', email: 'harpreet@singhhw.com', paymentTermsDays: 20 },
];

export const bankAccounts: BankAccount[] = [
  { id: 'b1', bankName: 'HDFC Bank', accountName: 'Current Account - Main', currentBalance: 1250000, lastUpdated: '2026-02-10' },
  { id: 'b2', bankName: 'ICICI Bank', accountName: 'Current Account - Operations', currentBalance: 875000, lastUpdated: '2026-02-09' },
  { id: 'b3', bankName: 'State Bank of India', accountName: 'Savings Account', currentBalance: 320000, lastUpdated: '2026-02-08' },
];

export const cheques: Cheque[] = [
  { id: 'c1', supplierId: 's1', chequeNumber: 'CHQ-001234', amount: 185000, chequeDate: '2026-02-12', bankAccountId: 'b1', status: 'upcoming', createdAt: '2026-02-05' },
  { id: 'c2', supplierId: 's2', chequeNumber: 'CHQ-001235', amount: 42000, chequeDate: '2026-02-13', bankAccountId: 'b1', status: 'upcoming', createdAt: '2026-02-06' },
  { id: 'c3', supplierId: 's3', chequeNumber: 'CHQ-001236', amount: 96500, chequeDate: '2026-02-15', bankAccountId: 'b2', status: 'upcoming', createdAt: '2026-02-07' },
  { id: 'c4', supplierId: 's4', chequeNumber: 'CHQ-001237', amount: 73000, chequeDate: '2026-02-17', bankAccountId: 'b1', status: 'issued', createdAt: '2026-02-08' },
  { id: 'c5', supplierId: 's5', chequeNumber: 'CHQ-001238', amount: 28500, chequeDate: '2026-02-11', bankAccountId: 'b2', status: 'upcoming', createdAt: '2026-02-04' },
  { id: 'c6', supplierId: 's1', chequeNumber: 'CHQ-001230', amount: 150000, chequeDate: '2026-02-01', bankAccountId: 'b1', status: 'cleared', createdAt: '2026-01-25' },
  { id: 'c7', supplierId: 's2', chequeNumber: 'CHQ-001231', amount: 35000, chequeDate: '2026-02-03', bankAccountId: 'b2', status: 'cleared', createdAt: '2026-01-28' },
  { id: 'c8', supplierId: 's3', chequeNumber: 'CHQ-001232', amount: 88000, chequeDate: '2026-01-28', bankAccountId: 'b1', status: 'bounced', createdAt: '2026-01-20' },
];

export const notifications: Notification[] = [
  { id: 'n1', message: 'Cheque CHQ-001238 for Singh Hardware (₹28,500) is due tomorrow', chequeId: 'c5', dateSent: '2026-02-10', type: 'in-app', read: false },
  { id: 'n2', message: 'Cheque CHQ-001234 for Gupta Steel Works (₹1,85,000) is due in 2 days', chequeId: 'c1', dateSent: '2026-02-10', type: 'in-app', read: false },
  { id: 'n3', message: 'Cheque CHQ-001235 for Sharma Electricals (₹42,000) is due in 3 days', chequeId: 'c2', dateSent: '2026-02-10', type: 'email', read: true },
  { id: 'n4', message: 'Cheque CHQ-001232 for Patel Logistics (₹88,000) has bounced', chequeId: 'c8', dateSent: '2026-02-08', type: 'in-app', read: true },
  { id: 'n5', message: 'Weekly cash flow summary: Total outflow next week ₹3,96,500', dateSent: '2026-02-07', type: 'email', read: true },
];

export const mlForecasts: MLForecast[] = [
  { date: '2026-02-10', predictedOutflow: 28500, actualOutflow: 28500 },
  { date: '2026-02-11', predictedOutflow: 0 },
  { date: '2026-02-12', predictedOutflow: 185000 },
  { date: '2026-02-13', predictedOutflow: 42000 },
  { date: '2026-02-14', predictedOutflow: 0 },
  { date: '2026-02-15', predictedOutflow: 96500 },
  { date: '2026-02-16', predictedOutflow: 0 },
  { date: '2026-02-17', predictedOutflow: 73000 },
  { date: '2026-02-18', predictedOutflow: 0 },
  { date: '2026-02-19', predictedOutflow: 45000 },
  { date: '2026-02-20', predictedOutflow: 0 },
  { date: '2026-02-21', predictedOutflow: 120000 },
  { date: '2026-02-22', predictedOutflow: 0 },
  { date: '2026-02-23', predictedOutflow: 65000 },
  { date: '2026-02-24', predictedOutflow: 0 },
  { date: '2026-02-25', predictedOutflow: 190000 },
  { date: '2026-02-26', predictedOutflow: 0 },
  { date: '2026-02-27', predictedOutflow: 85000 },
  { date: '2026-02-28', predictedOutflow: 0 },
  { date: '2026-03-01', predictedOutflow: 210000 },
  { date: '2026-03-05', predictedOutflow: 155000 },
  { date: '2026-03-10', predictedOutflow: 180000 },
  { date: '2026-03-15', predictedOutflow: 95000 },
  { date: '2026-03-20', predictedOutflow: 220000 },
  { date: '2026-03-25', predictedOutflow: 130000 },
  { date: '2026-03-30', predictedOutflow: 175000 },
  { date: '2026-04-05', predictedOutflow: 200000 },
  { date: '2026-04-10', predictedOutflow: 140000 },
];

export function getSupplierById(id: string): Supplier | undefined {
  return suppliers.find(s => s.id === id);
}

export function getBankAccountById(id: string): BankAccount | undefined {
  return bankAccounts.find(b => b.id === id);
}

export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

export function getDaysRemaining(dateStr: string): number {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const chequeDate = new Date(dateStr);
  chequeDate.setHours(0, 0, 0, 0);
  return Math.ceil((chequeDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
}

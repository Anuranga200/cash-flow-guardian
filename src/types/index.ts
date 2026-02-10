export type ChequeStatus = 'issued' | 'upcoming' | 'cleared' | 'bounced' | 'cancelled';

export interface Cheque {
  id: string;
  supplierId: string;
  chequeNumber: string;
  amount: number;
  chequeDate: string;
  bankAccountId: string;
  status: ChequeStatus;
  imageUrl?: string;
  notes?: string;
  createdAt: string;
}

export interface Supplier {
  id: string;
  company: string;
  contactPerson: string;
  phone: string;
  email: string;
  paymentTermsDays: number;
}

export interface BankAccount {
  id: string;
  bankName: string;
  accountName: string;
  currentBalance: number;
  lastUpdated: string;
}

export interface Notification {
  id: string;
  message: string;
  chequeId?: string;
  dateSent: string;
  type: 'in-app' | 'email';
  read: boolean;
}

export interface MLForecast {
  date: string;
  predictedOutflow: number;
  actualOutflow?: number;
}

import { useParams } from 'react-router-dom';
import { PageHeader } from '@/components/layout/PageHeader';
import { suppliers, cheques, getSupplierById, formatCurrency } from '@/data/mockData';
import { Building2, User, Phone, Mail, Clock, FileText } from 'lucide-react';

export default function SupplierDetailPage() {
  const { id } = useParams();
  const supplier = getSupplierById(id ?? '');

  if (!supplier) {
    return (
      <div className="min-h-screen bg-background">
        <PageHeader title="Supplier" showBack />
        <div className="page-container text-center text-muted-foreground py-20">Supplier not found</div>
      </div>
    );
  }

  const supplierCheques = cheques.filter(c => c.supplierId === supplier.id);
  const totalPaid = supplierCheques.filter(c => c.status === 'cleared').reduce((s, c) => s + c.amount, 0);
  const outstanding = supplierCheques.filter(c => c.status === 'upcoming' || c.status === 'issued');

  const infoItems = [
    { icon: Building2, label: 'Company', value: supplier.company },
    { icon: User, label: 'Contact', value: supplier.contactPerson },
    { icon: Phone, label: 'Phone', value: supplier.phone },
    { icon: Mail, label: 'Email', value: supplier.email },
    { icon: Clock, label: 'Payment Terms', value: `${supplier.paymentTermsDays} days` },
  ];

  return (
    <div className="min-h-screen bg-background">
      <PageHeader title={supplier.company} showBack />
      <div className="page-container space-y-5">
        <div className="rounded-xl border border-border/50 bg-card shadow-sm divide-y divide-border">
          {infoItems.map((item) => (
            <div key={item.label} className="flex items-center gap-3 p-3.5">
              <item.icon className="h-4 w-4 text-muted-foreground" />
              <div>
                <p className="text-xs text-muted-foreground">{item.label}</p>
                <p className="text-sm font-medium text-card-foreground">{item.value}</p>
              </div>
            </div>
          ))}
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div className="rounded-xl bg-card p-4 border border-border/50 shadow-sm">
            <p className="text-xs text-muted-foreground">Total Paid</p>
            <p className="text-lg font-bold text-success">{formatCurrency(totalPaid)}</p>
          </div>
          <div className="rounded-xl bg-card p-4 border border-border/50 shadow-sm">
            <p className="text-xs text-muted-foreground">Outstanding</p>
            <p className="text-lg font-bold text-warning">{formatCurrency(outstanding.reduce((s, c) => s + c.amount, 0))}</p>
          </div>
        </div>

        <section>
          <h2 className="section-title mb-3">Payment History</h2>
          <div className="space-y-2">
            {supplierCheques.length === 0 && (
              <p className="text-sm text-muted-foreground text-center py-8">No cheques found</p>
            )}
            {supplierCheques.map((cheque) => (
              <div key={cheque.id} className="flex items-center justify-between rounded-lg bg-card p-3 border border-border/50">
                <div>
                  <p className="text-sm font-medium text-card-foreground">{cheque.chequeNumber}</p>
                  <p className="text-xs text-muted-foreground capitalize">{cheque.status} · {new Date(cheque.chequeDate).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' })}</p>
                </div>
                <p className="font-semibold text-card-foreground">{formatCurrency(cheque.amount)}</p>
              </div>
            ))}
          </div>
        </section>
      </div>
    </div>
  );
}

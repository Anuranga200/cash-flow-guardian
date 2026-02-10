import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { PageHeader } from '@/components/layout/PageHeader';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';
import { suppliers, bankAccounts } from '@/data/mockData';
import { Camera, PenLine } from 'lucide-react';
import { toast } from 'sonner';

type InputMethod = 'choose' | 'photo' | 'manual';

export default function ChequeEntryPage() {
  const navigate = useNavigate();
  const [method, setMethod] = useState<InputMethod>('choose');
  const [formData, setFormData] = useState({
    supplierId: '',
    chequeNumber: '',
    chequeDate: '',
    amount: '',
    bankAccountId: '',
    notes: '',
  });

  const handleSave = () => {
    if (!formData.supplierId || !formData.chequeNumber || !formData.amount || !formData.chequeDate || !formData.bankAccountId) {
      toast.error('Please fill all required fields');
      return;
    }
    toast.success('Cheque saved successfully');
    navigate('/cheques');
  };

  if (method === 'choose') {
    return (
      <div className="min-h-screen bg-background">
        <PageHeader title="New Cheque" showBack />
        <div className="page-container space-y-4">
          <p className="text-sm text-muted-foreground">Choose how to enter the cheque details</p>
          <button
            onClick={() => setMethod('photo')}
            className="flex w-full items-center gap-4 rounded-xl border border-border/50 bg-card p-5 shadow-sm transition-all hover:shadow-md"
          >
            <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-info/10">
              <Camera className="h-6 w-6 text-info" />
            </div>
            <div className="text-left">
              <p className="font-semibold text-card-foreground">Upload Cheque Photo</p>
              <p className="text-xs text-muted-foreground">Take a photo and auto-extract details</p>
            </div>
          </button>
          <button
            onClick={() => setMethod('manual')}
            className="flex w-full items-center gap-4 rounded-xl border border-border/50 bg-card p-5 shadow-sm transition-all hover:shadow-md"
          >
            <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-accent/10">
              <PenLine className="h-6 w-6 text-accent" />
            </div>
            <div className="text-left">
              <p className="font-semibold text-card-foreground">Manual Entry</p>
              <p className="text-xs text-muted-foreground">Enter cheque details manually</p>
            </div>
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <PageHeader title={method === 'photo' ? 'Upload Cheque' : 'Manual Entry'} showBack />
      <div className="page-container space-y-5">
        {method === 'photo' && (
          <div className="flex flex-col items-center rounded-xl border-2 border-dashed border-border bg-muted/30 p-8">
            <Camera className="h-10 w-10 text-muted-foreground mb-3" />
            <p className="text-sm font-medium text-muted-foreground">Tap to capture or upload cheque</p>
            <input type="file" accept="image/*" capture="environment" className="absolute inset-0 opacity-0 cursor-pointer" />
          </div>
        )}

        <div className="space-y-4 rounded-xl border border-border/50 bg-card p-4 shadow-sm">
          <div className="space-y-1.5">
            <Label htmlFor="supplier">Supplier *</Label>
            <Select value={formData.supplierId} onValueChange={(v) => setFormData(p => ({ ...p, supplierId: v }))}>
              <SelectTrigger><SelectValue placeholder="Select supplier" /></SelectTrigger>
              <SelectContent>
                {suppliers.map(s => <SelectItem key={s.id} value={s.id}>{s.company}</SelectItem>)}
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="chequeNumber">Cheque Number *</Label>
            <Input
              id="chequeNumber"
              value={formData.chequeNumber}
              onChange={(e) => setFormData(p => ({ ...p, chequeNumber: e.target.value }))}
              placeholder="CHQ-XXXXXX"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1.5">
              <Label htmlFor="chequeDate">Cheque Date *</Label>
              <Input
                id="chequeDate"
                type="date"
                value={formData.chequeDate}
                onChange={(e) => setFormData(p => ({ ...p, chequeDate: e.target.value }))}
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="amount">Amount (₹) *</Label>
              <Input
                id="amount"
                type="number"
                value={formData.amount}
                onChange={(e) => setFormData(p => ({ ...p, amount: e.target.value }))}
                placeholder="0"
              />
            </div>
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="bank">Bank Account *</Label>
            <Select value={formData.bankAccountId} onValueChange={(v) => setFormData(p => ({ ...p, bankAccountId: v }))}>
              <SelectTrigger><SelectValue placeholder="Select bank account" /></SelectTrigger>
              <SelectContent>
                {bankAccounts.map(b => <SelectItem key={b.id} value={b.id}>{b.bankName} - {b.accountName}</SelectItem>)}
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="notes">Notes</Label>
            <Textarea
              id="notes"
              value={formData.notes}
              onChange={(e) => setFormData(p => ({ ...p, notes: e.target.value }))}
              placeholder="Optional notes"
              rows={2}
            />
          </div>
        </div>

        <Button onClick={handleSave} className="w-full bg-accent text-accent-foreground hover:bg-accent/90">
          Save Cheque
        </Button>
      </div>
    </div>
  );
}

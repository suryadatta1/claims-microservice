export interface Claim {
  id: string;
  status: 'RECEIVED' | 'ACCEPTED' | 'REJECTED';
  amount: number;
  description: string;
  createdAt: string;
}

export interface ClaimEvent {
  id: string;
  type: 'Claim.Requested' | 'Claim.Accepted' | 'Claim.Rejected';
  payload: Claim | any;
}

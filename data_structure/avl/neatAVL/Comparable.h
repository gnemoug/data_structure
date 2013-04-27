#if !defined(_COMPARABLE_H_)
#define _COMPARABLE_H_

class Comparable
{
   public : 
      virtual int CompareTo(const Comparable* pComparable) const = 0;
};

#endif

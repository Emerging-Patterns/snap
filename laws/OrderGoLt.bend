import Base

# LAW: once the walk has found a first char that is less, the rest of the
# strings does not change the order
law order_go_lt:
  for +a: String
  for +b: String
  {String.order.go(a, b, LT{}) == LT{} : Cmp}

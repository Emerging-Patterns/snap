import Base

# LAW: nor once it has found one that is greater
law order_go_gt:
  for +a: String
  for +b: String
  {String.order.go(a, b, GT{}) == GT{} : Cmp}

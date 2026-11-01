# how every effect cuts its wire back into arguments: at each NUL
import Base

# how every effect cuts its wire back into arguments: at each NUL. Law
# vocabulary: the effects do this in C and JS, and that they cut exactly
# here is trusted (trusted in src/effect.bend).
def wire.split(wr: String) -> List<&2, String>:
  String.split(wr, '\0')

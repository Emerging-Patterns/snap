import Base

# LAW: where the brackets fall in a run of appends does not change the run.
# This is what lets the chunk loop drop its accumulator: appending each chunk
# onto what came before it and appending each chunk onto what comes after it
# give the same string, and only the second is linear in the body.
law append_assoc:
  for a: String
  for b: String
  for c: String
  {String.append(String.append(a, b), c)
    == String.append(a, String.append(b, c)) : String}

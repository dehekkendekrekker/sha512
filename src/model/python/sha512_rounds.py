from hashlib import sha512


input = b"abc"
algo = sha512()


for i in range(2):
    print("Round: %s Input: %s" % (i, input.hex()))
    input = sha512(input).digest()

print("Result")
print(input.hex())


from hashlib import sha512


input = b"abc"
algo = sha512()


for i in range(2):
    algo.update(input)
    input = algo.digest()

print(input.hex())


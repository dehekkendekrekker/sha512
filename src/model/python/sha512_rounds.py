from hashlib import sha512
from argparse import ArgumentParser

parser = ArgumentParser()
parser.add_argument("--rounds",type=int, required=True)
args = parser.parse_args()
rounds = args.rounds


input = b"abc"
algo = sha512()


for i in range(rounds):
    print("Round: %s Input: %s" % (i+1, input.hex()))
    input = sha512(input).digest()

print("Result")
print(input.hex())


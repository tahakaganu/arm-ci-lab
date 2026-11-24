"""Tiny demo application used by the CI lab."""


def add(a, b):
    """Return the sum of a and b."""
    return a + b


if __name__ == "__main__":
    print(f"demo-app says 2 + 3 = {add(2, 3)}")

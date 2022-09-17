
# Example Timer

```
func timer() {
    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] _ in
        tick()
    }
}

func tick() {
    print("TICK")
}
```

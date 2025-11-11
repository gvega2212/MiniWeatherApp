import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv("../results/scaling_local_metrics.csv")

plt.figure()
plt.plot(df["ranks"], df["time_seconds"], marker="o")
plt.xlabel("MPI Ranks")
plt.ylabel("Execution Time (s)")
plt.title("Strong Scaling: Time vs MPI Ranks")
plt.grid(True)
plt.savefig("../results/time_vs_ranks.png")

plt.figure()
plt.plot(df["ranks"], df["speedup"], marker="o", color="green")
plt.xlabel("MPI Ranks")
plt.ylabel("Speedup (×)")
plt.title("Speedup vs MPI Ranks")
plt.grid(True)
plt.savefig("../results/speedup_vs_ranks.png")

print("✅ Plots saved to ../results/")

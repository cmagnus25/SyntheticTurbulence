import numpy as np
import matplotlib.pyplot as plt
n = 10000
m = 15
data = np.fromfile('test.dat', dtype=np.float64, count=n*m)
results = data.reshape(m, n)

it = np.arange(1,n,1)

u_avg = results[0,1:]
v_avg = results[1,1:]
w_avg = results[2,1:]

uu_avg = results[3,1:]
vv_avg = results[4,1:]
ww_avg = results[5,1:]

uv_avg = results[6,1:]
uw_avg = results[7,1:]
vw_avg = results[8,1:]


#plt.plot(it,u_avg,label='u')
plt.figure(1)
plt.plot(it, u_avg, 'r--', it, v_avg, 'b--', it, w_avg, 'k--')
plt.grid(True)
plt.legend()

plt.figure(2)
plt.plot(it, uu_avg, 'r--', it, vv_avg, 'b--', it, ww_avg, 'k--')
plt.grid(True)
plt.legend()

plt.figure(3)
plt.plot(it, uv_avg, 'r--', it, uw_avg, 'b--', it, vw_avg, 'k--')
plt.grid(True)
plt.legend()

plt.show()

#print(results[2,1:])

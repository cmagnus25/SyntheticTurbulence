import numpy as np
import matplotlib.pyplot as plt

n = 50000
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

uv = np.cov(u_avg,v_avg)
uv = uv[1][0]

uw = np.cov(u_avg,w_avg)
uw = uw[1][0]

vw = np.cov(v_avg,w_avg)
vw = vw[1][0]

print('UU: ' + str(np.var(u_avg)/0.75))
print('VV: ' + str(np.var(v_avg)/3.19))
print('WW: ' + str(np.var(w_avg)/1.49))
print('UV: ' + str(uv/(-0.66)))
print('UW: ' + str(uw/1))
print('VW: ' + str(vw/1))


isPlot = True

if isPlot:

	#plt.plot(it,u_avg,label='u')
	plt.figure(1)
	#plt.plot(it, u_avg, 'r--', it, v_avg, 'b--', it, w_avg, 'k--')
	plt.plot(it, u_avg, 'r--',label='u')
	plt.grid(True)
	plt.legend()

	plt.figure(2)
	#plt.plot(it, u_avg, 'r--', it, v_avg, 'b--', it, w_avg, 'k--')
	plt.plot(it, v_avg, 'b--', label='v')
	plt.grid(True)
	plt.legend()

	plt.figure(3)
	#plt.plot(it, u_avg, 'r--', it, v_avg, 'b--', it, w_avg, 'k--')
	plt.plot(it, w_avg, 'k--',label='w')
	plt.grid(True)
	plt.legend()

	plt.figure(4)
	plt.plot(it, uu_avg, 'r--', label='uu')
	plt.plot(it, vv_avg, 'b--', label='vv')
	plt.plot(it, ww_avg, 'k--', label='ww')
	plt.grid(True)
	plt.legend()
	
	plt.figure(5)
	plt.plot(it, uv_avg, 'r--', label='uv')
	plt.plot(it, uw_avg, 'b--', label='uw')
	plt.plot(it, vw_avg, 'k--', label='vw')
	plt.grid(True)
	plt.legend()
	plt.show()

#print(results[2,1:])

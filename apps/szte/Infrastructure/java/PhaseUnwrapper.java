/**
 * Copyright (c) 2014, University of Szeged, All rights reserved.
 */

import java.text.DecimalFormat;

public class PhaseUnwrapper {
	private final String name;
	private double lastWrapped = 0.0;
	private double lastUnwrapped = 0.0;

	public PhaseUnwrapper(String name) {
		this.name = name;
	}

	private static DecimalFormat FORMAT = new DecimalFormat("#0.00");

	public double unwrap(double phase) {
		if (phase < 0.0 || phase > 2 * Math.PI)
			throw new IllegalArgumentException();

		double speed = phase - lastWrapped;
		if (speed > Math.PI)
			speed -= 2 * Math.PI;
		else if (speed < -Math.PI)
			speed += 2 * Math.PI;

		lastWrapped = phase;
		lastUnwrapped += speed;

		if (name != null)
			System.out.println("unwrap " + name + ": "
					+ FORMAT.format(lastWrapped) + " "
					+ FORMAT.format(lastUnwrapped));

		return lastUnwrapped;
	}
}

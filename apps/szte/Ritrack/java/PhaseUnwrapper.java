/**
 * Copyright (c) 2014, University of Szeged, All rights reserved.
 */

import java.text.DecimalFormat;

public class PhaseUnwrapper {
	public final String name;

	public PhaseUnwrapper(String name) {
		this.name = name;
	}

	public static final int HISTORY = 8;

	public final double[] history = new double[HISTORY];
	public int headIndex = 0;
	public int maxIndex = 0;
	public int minIndex = 0;

	public void addSpeed(double speed) {
		if (--headIndex < 0)
			headIndex = HISTORY - 1;

		double minSpeed = history[minIndex];
		double maxSpeed = history[maxIndex];
		history[headIndex] = speed;

		if (speed < minSpeed)
			minIndex = headIndex;
		else if (minIndex == headIndex) {
			minIndex = 0;
			for (int i = 1; i < HISTORY; i++)
				if (history[i] < history[minIndex])
					minIndex = i;
		}

		if (speed > maxSpeed)
			maxIndex = headIndex;
		else if (maxIndex == headIndex) {
			maxIndex = 0;
			for (int i = 1; i < HISTORY; i++)
				if (history[i] > history[maxIndex])
					maxIndex = i;
		}
	}

	public static final DecimalFormat FORMAT = new DecimalFormat("#0.00");
	public static final double SPEED_GAP = 0.5 * Math.PI;
	public static final int DROPPED_LIMIT = 3;

	public double lastWrapped = 0.0;
	public double lastUnwrapped = 0.0;
	public int droppedCount = 0;

	public double unwrap(double phase) {
		if (phase < 0.0 || phase > 2 * Math.PI)
			throw new IllegalArgumentException();

		double speed = phase - lastWrapped;
		if (speed > Math.PI)
			speed -= 2 * Math.PI;
		else if (speed < -Math.PI)
			speed += 2 * Math.PI;

		double minSpeed = history[minIndex];
		double maxSpeed = history[maxIndex];

		if (droppedCount >= DROPPED_LIMIT
				|| (minSpeed - SPEED_GAP <= speed && speed <= maxSpeed
						+ SPEED_GAP)) {
			lastWrapped = phase;
			lastUnwrapped += speed;
			addSpeed(speed);
		} else
			droppedCount += 1;

		if (name != null)
			System.out
					.println("unwrap " + name + ": " + droppedCount + " "
							+ FORMAT.format(phase) + " "
							+ FORMAT.format(lastUnwrapped));

		return lastUnwrapped;
	}
}

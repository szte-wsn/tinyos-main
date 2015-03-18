public interface RelativePhaseListener {
	void relativePhaseReceived(double relativePhase, double avg_period, int status, int slotId, int reference, int other);
}

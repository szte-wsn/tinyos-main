public class SyncMsg extends net.tinyos.message.Message {

	public static final int MINIMUM_MESSAGE_SIZE = 6;
	public static final int SIZE_FRAME = 1;
	public static final int SIZE_FREQ = 1;
	public static final int SIZE_PHASE = 1;
	public static final int SETTINGS_SIZE =  SIZE_FREQ + SIZE_PHASE;

	/** The Active Message type associated with this message. */
	public static final int AM_TYPE = 61;

	/** Create a new SyncMsg of size 42. */
	public SyncMsg() {
		super(MINIMUM_MESSAGE_SIZE);
		amTypeSet(AM_TYPE);
	}

	/** Create a new SyncMsg of the given data_length. */
	public SyncMsg(int data_length) {
		super(data_length);
		amTypeSet(AM_TYPE);
	}

	/**
	 * Create a new SyncMsg with the given data_length and base offset.
	 */
	public SyncMsg(int data_length, int base_offset) {
		super(data_length, base_offset);
		amTypeSet(AM_TYPE);
	}

	/**
	 * Create a new SyncMsg using the given byte array as backing store.
	 */
	public SyncMsg(byte[] data) {
		super(data);
		amTypeSet(AM_TYPE);
	}

	/**
	 * Create a new SyncMsg using the given byte array as backing store, with
	 * the given base offset.
	 */
	public SyncMsg(byte[] data, int base_offset) {
		super(data, base_offset);
		amTypeSet(AM_TYPE);
	}

	/**
	 * Create a new SyncMsg using the given byte array as backing store, with
	 * the given base offset and data length.
	 */
	public SyncMsg(byte[] data, int base_offset, int data_length) {
		super(data, base_offset, data_length);
		amTypeSet(AM_TYPE);
	}

	/**
	 * Create a new SyncMsg embedded in the given message at the given base
	 * offset.
	 */
	public SyncMsg(net.tinyos.message.Message msg, int base_offset) {
		super(msg, base_offset, MINIMUM_MESSAGE_SIZE);
		amTypeSet(AM_TYPE);
	}

	/**
	 * Create a new SyncMsg embedded in the given message at the given base
	 * offset and length.
	 */
	public SyncMsg(net.tinyos.message.Message msg, int base_offset,
			int data_length) {
		super(msg, base_offset, data_length);
		amTypeSet(AM_TYPE);
	}

	public int getSettingsNum() {
		return (data_length - MINIMUM_MESSAGE_SIZE) / SETTINGS_SIZE;
	}

	public short get_frame() {
		return (short) getUIntBEElement(0, SIZE_FRAME * 8);
	}

	public int getElement_freq(int index1) {
		int offset = 8 * (SIZE_FRAME + index1 * SIZE_FREQ);
		return (int) getUIntBEElement(offset, SIZE_FREQ * 8);
	}

	public short getElement_phase(int index1) {
		int offset = 8 * (SIZE_FRAME + getSettingsNum() * SIZE_FREQ + index1 * SIZE_PHASE);
		return (short) getUIntBEElement(offset, SIZE_PHASE * 8);
	}

	public int[] get_freq() {
		int[] tmp = new int[getSettingsNum()];
		for (int index0 = 0; index0 < getSettingsNum(); index0++) {
			tmp[index0] = getElement_freq(index0);
		}
		return tmp;
	}

	public short[] get_phase() {
		short[] tmp = new short[getSettingsNum()];
		for (int index0 = 0; index0 < getSettingsNum(); index0++) {
			tmp[index0] = getElement_phase(index0);
		}
		return tmp;
	}
}

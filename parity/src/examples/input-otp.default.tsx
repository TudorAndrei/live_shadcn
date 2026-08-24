import { InputOTP } from "@upstream/shadcn/ui/input-otp";

// Ported from `StorybookWeb.Examples.input_otp_default/1`.
export default function InputOtpDefault() {
  return (
    <InputOTP
      aria-label="Verification code"
      className="max-w-48"
      maxLength={6}
      readOnly
      value="123456"
    />
  );
}

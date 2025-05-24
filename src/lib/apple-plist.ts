/**
 * Converts an Apple PLIST date (float representing seconds since 2001-01-01) to a JavaScript Date
 * in local timezone
 * @param plistDate The PLIST date as a float
 * @returns A JavaScript Date object in local timezone, or null if the input is invalid
 */
export function plistDateToJSDate(plistDate: number | null): Date | null {
  if (plistDate === null || plistDate === undefined) {
    return null;
  }

  // Apple PLIST dates are seconds since 2001-01-01
  const appleEpoch = new Date("2001-01-01T00:00:00Z").getTime();
  const milliseconds = appleEpoch + plistDate * 1000;

  // Create UTC date
  const utcDate = new Date(milliseconds);

  // Convert to local time by adjusting for timezone offset
  const localDate = new Date(
    utcDate.getTime() - utcDate.getTimezoneOffset() * 60000
  );

  return localDate;
}
